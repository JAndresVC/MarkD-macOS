#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="MarkD"
BUNDLE_ID="com.Andres.MarkD"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/MarkD.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

stop_running_app() {
    if ! /usr/bin/pgrep -x "$APP_NAME" >/dev/null 2>&1; then
        return
    fi

    # Ask AppKit to quit normally so unsaved documents can present their save
    # prompt. Never force-kill a document editor from the launcher.
    /usr/bin/osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true

    for _ in {1..50}; do
        if ! /usr/bin/pgrep -x "$APP_NAME" >/dev/null 2>&1; then
            return
        fi
        /bin/sleep 0.1
    done

    echo "MarkD sigue abierto, posiblemente esperando que guardes un documento. Se canceló la recompilación para no perder cambios." >&2
    exit 1
}

build_app() {
    echo "Compilando MarkD..."
    env DEVELOPER_DIR="$DEVELOPER_DIR" /usr/bin/xcodebuild \
        -quiet \
        -project "$PROJECT" \
        -scheme "$APP_NAME" \
        -configuration Debug \
        -destination "platform=macOS" \
        -derivedDataPath "$DERIVED_DATA" \
        CODE_SIGNING_ALLOWED=NO \
        build
}

launch_app() {
    /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
    run)
        stop_running_app
        build_app
        launch_app
        ;;
    --debug|debug)
        stop_running_app
        build_app
        /usr/bin/lldb -- "$APP_BINARY"
        ;;
    --logs|logs)
        stop_running_app
        build_app
        launch_app
        exec /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
        ;;
    --telemetry|telemetry)
        stop_running_app
        build_app
        launch_app
        exec /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
        ;;
    --verify|verify)
        stop_running_app
        build_app
        launch_app
        for _ in {1..50}; do
            if /usr/bin/pgrep -x "$APP_NAME" >/dev/null 2>&1; then
                echo "MarkD se compiló y abrió correctamente."
                exit 0
            fi
            /bin/sleep 0.1
        done
        echo "MarkD se compiló, pero el proceso no apareció después de abrir la app." >&2
        exit 1
        ;;
    *)
        echo "Uso: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
        exit 2
        ;;
esac
