#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
app_name="MarkD"
version="0.2.0"
release_channel="Beta 9"
safe_channel=${release_channel// /-}
default_output="$project_dir/dist/$app_name-$version-$safe_channel.dmg"
output_path=${1:-$default_output}
derived_data="$project_dir/.build/ReleaseDerivedData"
app_path="$derived_data/Build/Products/Release/$app_name.app"
developer_dir=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}

if [[ -e "$output_path" ]]; then
    print -u2 "No se sobrescribió el archivo existente: $output_path"
    exit 2
fi

print "Compilando $app_name $version $release_channel…"
env DEVELOPER_DIR="$developer_dir" /usr/bin/xcodebuild \
    -quiet \
    -project "$project_dir/MarkD.xcodeproj" \
    -scheme "$app_name" \
    -configuration Release \
    -destination "platform=macOS" \
    -derivedDataPath "$derived_data" \
    build

actual_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app_path/Contents/Info.plist")
actual_sdk=$(/usr/libexec/PlistBuddy -c "Print :DTSDKName" "$app_path/Contents/Info.plist")
actual_channel=$(/usr/libexec/PlistBuddy -c "Print :MarkDReleaseChannel" "$app_path/Contents/Info.plist")

if [[ "$actual_version" != "$version" || "$actual_channel" != "$release_channel" ]]; then
    print -u2 "Los metadatos compilados no coinciden con $version $release_channel."
    exit 1
fi

sdk_version=${actual_sdk#macosx}
if (( ${sdk_version%%.*} < 27 )); then
    print -u2 "$release_channel requiere SDK macOS 27 o posterior para incluir las pestañas nativas. SDK encontrado: $actual_sdk"
    exit 1
fi

"$script_dir/test_bundle_metadata.sh" "$app_path"
/usr/bin/codesign --verify --deep --strict "$app_path"

staging_root=$(mktemp -d /tmp/markd-dmg.XXXXXX)
trap 'rm -rf "$staging_root"' EXIT
staging_dir="$staging_root/$app_name $version $release_channel"
/bin/mkdir -p "$staging_dir" "${output_path:h}"
/usr/bin/ditto "$app_path" "$staging_dir/$app_name.app"
/bin/ln -s /Applications "$staging_dir/Applications"

print "Creando ${output_path:t}…"
/usr/bin/hdiutil create \
    -volname "$app_name $version $release_channel" \
    -srcfolder "$staging_dir" \
    -format UDZO \
    "$output_path"

/usr/bin/hdiutil verify "$output_path"
print "DMG listo: $output_path"
