#!/usr/bin/env bash
# PostToolUse: remember that this session actually changed something worth saving.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/memory-common.sh"
read_hook_input

memory_enabled || exit 0
[ -f "$MEMORY_CONFIG" ] || exit 0

SESSION_ID="$(hook_field '.session_id')"
TOOL="$(hook_field '.tool_name')"

case "$TOOL" in
  Edit|Write|NotebookEdit|MultiEdit)
    ;;
  Bash)
    CMD="$(hook_field '.tool_input.command')"
    # Only shell commands that mutate project state count as real work.
    MUTATING='(^|[;&|[:space:]])(git[[:space:]]+(commit|push|merge|rebase|revert|cherry-pick)|npm[[:space:]]+(install|publish)|pnpm[[:space:]]+(install|add)|yarn[[:space:]]+add|pip[[:space:]]+install|make|docker|terraform|mv|cp|tee)([[:space:]]|$)'
    printf '%s' "$CMD" | grep -Eq "$MUTATING" || exit 0
    ;;
  *)
    exit 0
    ;;
esac

printf '%s\n' "$TOOL" >> "$(dirty_file "$SESSION_ID")"
# New work after a save means the saved summary is stale again.
rm -f "$(saved_file "$SESSION_ID")" 2>/dev/null || true
exit 0
