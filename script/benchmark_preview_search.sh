#!/bin/zsh
set -euo pipefail
script_dir=${0:A:h}
project_dir=${script_dir:h}
test_dir=$(mktemp -d /tmp/markd-search-benchmark.XXXXXX)
trap 'rm -rf "$test_dir"' EXIT
env DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" xcrun swiftc -O \
    "$project_dir/MarkD/AppTheme.swift" \
    "$project_dir/MarkD/MarkdownParser.swift" \
    "$project_dir/MarkD/PreviewSearch.swift" \
    "$project_dir/Tests/PreviewSearchBenchmark.swift" \
    -module-cache-path "$test_dir/module-cache" \
    -o "$test_dir/PreviewSearchBenchmark"
"$test_dir/PreviewSearchBenchmark"
