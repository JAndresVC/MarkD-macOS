#!/bin/zsh
set -uo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    print "Uso: ${0:t} [/ruta/a/MarkD.app]"
    print "Ejecuta las suites automáticas; la ruta opcional añade metadatos del bundle."
    print "Admite DEVELOPER_DIR. Conserva logs y códigos en .build/TestResults."
    print "Excluye benchmark y AppleScript UI: se ejecutan por separado."
    exit 0
fi
if (( $# > 1 )) || [[ "${1:-}" == -* ]]; then
    print -u2 "Uso: ${0:t} [/ruta/a/MarkD.app] (o --help)"
    exit 2
fi

mkdir -p "$project_dir/.build/TestResults" || exit 1
log_dir=$(mktemp -d "$project_dir/.build/TestResults/run.XXXXXX") || exit 1
developer_dir=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
integer failures=0
summary=()

run_suite() {
    local suite=$1
    shift
    local code
    print "\nEjecutando $suite"
    if env DEVELOPER_DIR="$developer_dir" "$script_dir/$suite.sh" "$@" > "$log_dir/$suite.log" 2>&1; then
        code=0
    else
        code=$?
    fi
    print -r -- "$code" > "$log_dir/$suite.exit"
    cat "$log_dir/$suite.log"
    summary+=("$suite: salida $code")
    (( code == 0 )) || (( failures += 1 ))
}

for suite in test_parser test_themes test_accessibility test_localization \
    test_preview_search test_preview_scroll test_preview_document test_document_safety test_document_io \
    test_editor_navigation test_editor_find; do
    run_suite "$suite"
done
if (( $# == 1 )); then
    run_suite test_bundle_metadata "$1"
else
    print "\nMetadatos omitidos: pasa la ruta del bundle para verificarlos."
fi

print "\nResumen:"
printf '%s\n' "${summary[@]}"
print "Logs y códigos: $log_dir"
print "Excluidos: benchmark y AppleScript UI (requieren un pase independiente)."
print "Suites: ${#summary[@]}; fallos: $failures"
(( failures == 0 ))
