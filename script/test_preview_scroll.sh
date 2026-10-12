#!/bin/zsh
set -euo pipefail
script_dir=${0:A:h}
project_dir=${script_dir:h}
test_dir=$(mktemp -d /tmp/markd-preview-scroll.XXXXXX)
trap 'rm -rf "$test_dir"' EXIT
env DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" xcrun swiftc \
    "$project_dir/MarkD/AppTheme.swift" \
    "$project_dir/MarkD/MarkdownParser.swift" \
    "$project_dir/MarkD/PreviewSearch.swift" \
    "$project_dir/MarkD/PreviewSearchText.swift" \
    "$project_dir/Tests/PreviewSearchScrollTests.swift" \
    -module-cache-path "$test_dir/module-cache" \
    -o "$test_dir/PreviewSearchScrollTests"
"$test_dir/PreviewSearchScrollTests"
