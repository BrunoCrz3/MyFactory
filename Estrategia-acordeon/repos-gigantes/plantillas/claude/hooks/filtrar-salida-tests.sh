#!/usr/bin/env bash
# Hook PreToolUse (matcher: Bash) · Reescribe los comandos de test para que al contexto
# solo lleguen los fallos, o el resumen final si todo pasa.
#
# Diferencias con el ejemplo de la documentación (cmd | grep | head):
#   - Conserva el código de salida real del comando: una suite roja no puede parecer verde.
#   - Guarda la salida completa en un fichero temporal y devuelve su ruta, para que el agente
#     pueda leer el detalle si lo necesita (compresión restaurable).
#   - Solo toca comandos de test simples. Si hay ; & | ` < > $( o saltos de línea, no hace nada.
#   - No emite permissionDecision: el comando reescrito pasa por el flujo normal de permisos.
#   - Sin jq, no hace nada (no rompe la sesión).
#
# Requisitos: bash y jq. En Windows, Git Bash con jq en el PATH.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Comandos compuestos: fuera. Evita reescribir algo que no entendemos.
case "$cmd" in
  *[';&|<>`']* | *'$('* ) exit 0 ;;
esac
[[ "$cmd" == *$'\n'* ]] && exit 0

# Comandos de test reconocidos. Ajustar al repositorio del cliente.
re='^((npm|pnpm|yarn)( run)? test|npx (jest|vitest)|(uv run )?pytest|go test|cargo test|dotnet test|mvn( -q)? test|(\./)?gradlew? test)( |$)'
[[ "$cmd" =~ $re ]] || exit 0

# Patrones de fallo. Ajustar al runner del cliente.
fallos='(FAIL|FAILED|ERROR|Error:|error:|panic:|Exception|AssertionError)'

filtered='log=$(mktemp); ( '"$cmd"' ) >"$log" 2>&1; rc=$?; '
filtered+='if [ $rc -eq 0 ]; then tail -n 5 "$log"; '
filtered+='else grep -n -E -A5 "'"$fallos"'" "$log" | head -n 150; fi; '
filtered+='echo "--- exit=$rc · $(wc -l <"$log") líneas · salida completa: $log"; exit $rc'

printf '%s' "$input" | jq --arg c "$filtered" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: (.tool_input + {command: $c})}}'
