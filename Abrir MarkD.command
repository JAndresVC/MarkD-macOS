#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# A second double-click should focus MarkD, not close a document that the user
# may still be editing. The development Run action remains available when a
# fresh rebuild is wanted.
if /usr/bin/pgrep -x "MarkD" >/dev/null 2>&1; then
    /usr/bin/osascript -e "tell application id \"com.Andres.MarkD\" to activate"
    exit 0
fi

exec "$ROOT_DIR/script/build_and_run.sh"
