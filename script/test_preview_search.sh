#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
test_dir=$(mktemp -d /tmp/markd-preview-search-tests.XXXXXX)
trap 'rm -rf "$test_dir"' EXIT

developer_dir=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
mkdir -p "$test_dir/module-cache"

env DEVELOPER_DIR="$developer_dir" xcrun swiftc \
    "$project_dir/MarkD/AppTheme.swift" \
    "$project_dir/MarkD/MarkdownParser.swift" \
    "$project_dir/MarkD/PreviewSearch.swift" \
    "$project_dir/MarkD/DerivedValueCache.swift" \
    "$project_dir/Tests/PreviewSearchTests.swift" \
    -module-cache-path "$test_dir/module-cache" \
    -o "$test_dir/PreviewSearchTests"

"$test_dir/PreviewSearchTests"
