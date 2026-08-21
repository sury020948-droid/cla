#!/usr/bin/env bash
# Shared state helpers for the NotebookLM "second brain" automation.
set -uo pipefail

MEMORY_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
MEMORY_STATE_DIR="$MEMORY_ROOT/.claude/.memory-state"
MEMORY_CONFIG="$MEMORY_ROOT/.claude/memory.json"

mkdir -p "$MEMORY_STATE_DIR" 2>/dev/null || true

# Reads the hook payload from stdin once and caches it in HOOK_INPUT.
read_hook_input() {
  HOOK_INPUT="$(cat)"
}

hook_field() {
  printf '%s' "${HOOK_INPUT:-}" | jq -r "${1} // empty" 2>/dev/null
}

memory_config() {
  [ -f "$MEMORY_CONFIG" ] || { printf ''; return; }
  jq -r "${1} // empty" "$MEMORY_CONFIG" 2>/dev/null
}

memory_enabled() {
  # Not via memory_config: jq's `//` treats `false` as empty, which would read
  # an explicit "enabled": false back as unset.
  local enabled
  [ -f "$MEMORY_CONFIG" ] || return 0
  enabled="$(jq -r '.enabled' "$MEMORY_CONFIG" 2>/dev/null)"
  [ "$enabled" != "false" ]
}

dirty_file() { printf '%s/%s.dirty' "$MEMORY_STATE_DIR" "${1:-unknown}"; }
saved_file() { printf '%s/%s.saved' "$MEMORY_STATE_DIR" "${1:-unknown}"; }
# Setup writes a real notebook id; the checked-in template carries a placeholder.
# Until that is replaced there is no notebook to read from or write to, so the
# hooks stay quiet rather than demanding a save that cannot land.
memory_ready() {
  local id
  id="$(memory_config '.notebook_id')"
  [ -n "$id" ] && [ "$id" != "abc123" ]
}
