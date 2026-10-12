#!/bin/zsh
set -euo pipefail
script_dir=${0:A:h}
project_dir=${script_dir:h}
test_dir=$(mktemp -d /tmp/markd-document-io.XXXXXX)
trap 'rm -rf "$test_dir"' EXIT
env DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" xcrun swiftc \
    "$project_dir/MarkD/MarkDocument.swift" \
    "$project_dir/Tests/DocumentIOTests.swift" \
    -module-cache-path "$test_dir/module-cache" \
    -o "$test_dir/DocumentIOTests"
"$test_dir/DocumentIOTests"
