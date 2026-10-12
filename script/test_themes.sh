#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
test_dir=$(mktemp -d /tmp/markd-theme-tests.XXXXXX)
trap 'rm -rf "$test_dir"' EXIT

developer_dir=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
mkdir -p "$test_dir/module-cache"

env DEVELOPER_DIR="$developer_dir" xcrun swiftc \
    "$project_dir/MarkD/AppTheme.swift" \
    "$project_dir/Tests/ThemePaletteTests.swift" \
    -module-cache-path "$test_dir/module-cache" \
    -o "$test_dir/ThemePaletteTests"

"$test_dir/ThemePaletteTests"

env DEVELOPER_DIR="$developer_dir" xcrun swiftc \
    "$project_dir/MarkD/AppTheme.swift" \
    "$project_dir/MarkD/ThemePresentation.swift" \
    "$project_dir/Tests/WindowAppearanceTests.swift" \
    -module-cache-path "$test_dir/module-cache" \
    -o "$test_dir/WindowAppearanceTests"

"$test_dir/WindowAppearanceTests"

env DEVELOPER_DIR="$developer_dir" xcrun swiftc \
    "$project_dir/MarkD/AppTheme.swift" \
    "$project_dir/MarkD/EditorView.swift" \
    "$project_dir/Tests/EditorStyleCacheTests.swift" \
    -module-cache-path "$test_dir/module-cache" \
    -o "$test_dir/EditorStyleCacheTests"

"$test_dir/EditorStyleCacheTests"
