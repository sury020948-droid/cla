#!/usr/bin/env bash
# Marker written by the memory-save skill once the summary really is in NotebookLM.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/memory-common.sh"

SESSION_ID="${1:-}"
if [ -z "$SESSION_ID" ]; then
  echo "usage: memory-saved.sh <session_id>" >&2
  exit 2
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$(saved_file "$SESSION_ID")"
rm -f "$(dirty_file "$SESSION_ID")" 2>/dev/null || true
echo "memory: session $SESSION_ID marked as saved"
