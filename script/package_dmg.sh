#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
app_name="MarkD"
version="0.2.0"
release_channel="Beta 12"
safe_channel=${release_channel// /-}
default_output="$project_dir/dist/$app_name-$version-$safe_channel-Installer.dmg"
output_path=${1:-$default_output}
derived_data="$project_dir/.build/ReleaseDerivedData"
app_path=${MARKD_APP_PATH:-"$derived_data/Build/Products/Release/$app_name.app"}
developer_dir=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
dmgbuild="$project_dir/.build/dmg-tools/bin/dmgbuild"

if [[ -e "$output_path" ]]; then
    print -u2 "No se sobrescribió el archivo existente: $output_path"
    exit 2
fi

if [[ ! -x "$dmgbuild" ]]; then
    print -u2 "Prepara las herramientas del instalador desde la raíz del proyecto:"
    print -u2 "uv venv .build/dmg-tools"
    print -u2 "uv pip install --python .build/dmg-tools/bin/python --require-hashes -r script/dmg/requirements.txt"
    exit 1
fi

if [[ -z ${MARKD_APP_PATH:-} ]]; then
    print "Compilando $app_name $version $release_channel…"
    env DEVELOPER_DIR="$developer_dir" /usr/bin/xcodebuild \
        -quiet \
        -project "$project_dir/MarkD.xcodeproj" \
        -scheme "$app_name" \
        -configuration Release \
        -destination "platform=macOS" \
        -derivedDataPath "$derived_data" \
        build
fi

"$script_dir/test_bundle_metadata.sh" "$app_path"

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

/usr/bin/codesign --verify --deep --strict "$app_path"

/bin/mkdir -p "${output_path:h}"

print "Creando ${output_path:t}…"
"$dmgbuild" \
    -s "$script_dir/dmg/settings.py" \
    -D "app=$app_path" \
    -D "background=$script_dir/dmg/background.png" \
    "Instalar $app_name" \
    "$output_path"

/usr/bin/hdiutil verify "$output_path"
print "DMG listo: $output_path"
