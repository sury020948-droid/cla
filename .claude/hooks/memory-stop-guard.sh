#!/usr/bin/env bash
# Stop: if this session changed things and was never written to NotebookLM,
# block the stop exactly once and make Claude run the memory-save skill.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/memory-common.sh"
read_hook_input

memory_enabled || exit 0
[ -f "$MEMORY_CONFIG" ] || exit 0
memory_ready || exit 0

SESSION_ID="$(hook_field '.session_id')"
STOP_ACTIVE="$(hook_field '.stop_hook_active')"

# Already blocked once this turn -> never block again (no infinite loop).
[ "$STOP_ACTIVE" = "true" ] && exit 0

DIRTY="$(dirty_file "$SESSION_ID")"
SAVED="$(saved_file "$SESSION_ID")"

[ -f "$DIRTY" ] || exit 0
[ -f "$SAVED" ] && exit 0

CHANGES="$(sort "$DIRTY" | uniq -c | tr '\n' ' ')"
NOTEBOOK="$(memory_config '.notebook_name')"
NOTEBOOK="${NOTEBOOK:-Claude Memory}"

REASON="Unsaved session memory. This session modified the project ($CHANGES) but nothing
was written to the \"$NOTEBOOK\" notebook yet.

Run the memory-save skill now: summarise this session (what was asked, what changed,
which decisions were made and why, what is still open), write it to NotebookLM with the
notebooklm add_source tool, then run:

  .claude/hooks/memory-saved.sh \"$SESSION_ID\"

Do that, then stop. Do not start unrelated new work."

jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
