#!/bin/zsh

set -euo pipefail

app_path=${1:?"usage: test_bundle_metadata.sh /path/to/MarkD.app"}
plist="$app_path/Contents/Info.plist"

if [[ ! -f "$plist" ]]; then
    print -u2 "FAIL: bundle Info.plist not found at $plist"
    exit 1
fi

markdown_type=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDocumentTypes:0:LSItemContentTypes:0" "$plist" 2>/dev/null || true)
plain_text_type=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDocumentTypes:1:LSItemContentTypes:0" "$plist" 2>/dev/null || true)
imported_identifier=$(/usr/libexec/PlistBuddy -c "Print :UTImportedTypeDeclarations:0:UTTypeIdentifier" "$plist" 2>/dev/null || true)
imported_parent=$(/usr/libexec/PlistBuddy -c "Print :UTImportedTypeDeclarations:0:UTTypeConformsTo:0" "$plist" 2>/dev/null || true)
markdown_extension=$(/usr/libexec/PlistBuddy -c "Print :UTImportedTypeDeclarations:0:UTTypeTagSpecification:public.filename-extension:0" "$plist" 2>/dev/null || true)
long_markdown_extension=$(/usr/libexec/PlistBuddy -c "Print :UTImportedTypeDeclarations:0:UTTypeTagSpecification:public.filename-extension:1" "$plist" 2>/dev/null || true)
markdown_mime=$(/usr/libexec/PlistBuddy -c "Print :UTImportedTypeDeclarations:0:UTTypeTagSpecification:public.mime-type:0" "$plist" 2>/dev/null || true)
icon_name=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$plist" 2>/dev/null || true)
short_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null || true)
build_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$plist" 2>/dev/null || true)
release_channel=$(/usr/libexec/PlistBuddy -c "Print :MarkDReleaseChannel" "$plist" 2>/dev/null || true)

if [[ "$markdown_type" != "net.daringfireball.markdown" ]]; then
    print -u2 "FAIL: Markdown document type is not registered in the app bundle"
    exit 1
fi

if [[ "$plain_text_type" != "public.plain-text" ]]; then
    print -u2 "FAIL: plain-text document type is not registered in the app bundle"
    exit 1
fi

if [[ "$imported_identifier" != "net.daringfireball.markdown" ||
      "$imported_parent" != "public.plain-text" ||
      "$markdown_extension" != "md" ||
      "$long_markdown_extension" != "markdown" ||
      "$markdown_mime" != "text/markdown" ]]; then
    print -u2 "FAIL: Markdown UTI has no complete extension/MIME declaration"
    exit 1
fi

if [[ "$icon_name" != "AppIcon" || ! -f "$app_path/Contents/Resources/AppIcon.icns" ]]; then
    print -u2 "FAIL: compiled app icon is missing from the bundle"
    exit 1
fi

if [[ "$short_version" != "0.2.0" || "$build_version" != "9" || "$release_channel" != "Beta 9" ]]; then
    print -u2 "FAIL: expected MarkD 0.2.0 Beta 9 (build 9), found $short_version $release_channel (build $build_version)"
    exit 1
fi

print "BundleMetadataTests: passed"
