#!/usr/bin/env bash
# Reports what of this project's setup is actually working on this machine.
#   ./scripts/check-setup.sh
# Read-only: it inspects, it never installs or changes anything.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PASS=0; FAIL=0; WARN=0
ok()   { printf '  \033[1;32mOK\033[0m   %s\n' "$*"; PASS=$((PASS+1)); }
bad()  { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
soft() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; WARN=$((WARN+1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# $1 command, $2 label, $3 "optional" to downgrade a miss to SKIP
have() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$2 — $("$1" --version 2>&1 | head -1)"
  elif [ "${3:-}" = "optional" ]; then
    soft "$2 not installed (optional)"
  else
    bad "$2 not found — reopen the terminal, or reinstall it"
  fi
}

head_ "1. Tools"
have git      "git"
have node     "node"
have jq       "jq"
have claude   "claude"
have graphify "graphify"
have headroom "headroom" optional

head_ "2. Project"
if [ -d .git ]; then
  ok "in the repo — $(pwd)"
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [ "$BRANCH" = "claude/notion-setup-automation-p8aseq" ] \
    && ok "on branch $BRANCH" \
    || bad "on branch '$BRANCH' — run: git checkout claude/notion-setup-automation-p8aseq"
  git diff --quiet HEAD 2>/dev/null && ok "no uncommitted changes" || soft "working tree has local edits"
else
  bad "not a git repository — cd into the cla folder first"
fi

head_ "3. Memory config"
if [ -f .claude/memory.json ]; then
  ID="$(jq -r '.notebook_id // empty' .claude/memory.json 2>/dev/null)"
  EN="$(jq -r '.enabled' .claude/memory.json 2>/dev/null)"
  if [ -z "$ID" ] || [ "$ID" = "abc123" ]; then
    bad "notebook not configured yet — run ./scripts/setup-notebooklm.sh \"<your notebook URL>\""
  else
    ok "notebook id $ID"
  fi
  [ "$EN" = "false" ] && soft "memory is disabled (--enable turns it back on)" || ok "memory enabled"
else
  bad ".claude/memory.json missing — run ./scripts/setup-notebooklm.sh \"<your notebook URL>\""
fi

head_ "4. Google login"
AUTH="${XDG_DATA_HOME:-$HOME/.local/share}/notebooklm-mcp/chrome_profile"
[ "$(uname)" = "Darwin" ] && AUTH="$HOME/Library/Application Support/notebooklm-mcp/chrome_profile"
if [ -d "$AUTH" ] && [ -n "$(ls -A "$AUTH" 2>/dev/null)" ]; then
  ok "Chrome profile has a stored session"
else
  bad "not logged in — start claude and say: run setup_auth"
fi

head_ "5. Hooks"
for h in memory-session-start memory-mark-dirty memory-stop-guard memory-saved; do
  [ -x ".claude/hooks/$h.sh" ] && ok "$h.sh" || bad "$h.sh missing or not executable"
done

# The guard is the piece that actually blocks a session; prove it both ways
# rather than trusting that the file exists.
if [ -x .claude/hooks/memory-stop-guard.sh ]; then
  T="checkup-$$"
  printf 'Edit\n' > ".claude/.memory-state/$T.dirty" 2>/dev/null
  OUT="$(echo "{\"session_id\":\"$T\",\"stop_hook_active\":false}" | .claude/hooks/memory-stop-guard.sh 2>/dev/null)"
  echo "$OUT" | grep -q '"block"' \
    && ok "stop guard blocks an unsaved session" \
    || bad "stop guard did not block — is the notebook configured?"
  .claude/hooks/memory-saved.sh "$T" >/dev/null 2>&1
  OUT="$(echo "{\"session_id\":\"$T\",\"stop_hook_active\":false}" | .claude/hooks/memory-stop-guard.sh 2>/dev/null)"
  [ -z "$OUT" ] && ok "stop guard stays quiet once saved" || bad "stop guard still blocks after a save"
  rm -f ".claude/.memory-state/$T".* 2>/dev/null
fi

head_ "6. Graph"
if command -v graphify >/dev/null 2>&1 && [ -f graphify-out/graph.json ]; then
  ok "graph present — $(jq -r '(.nodes|length) as $n | (.links|length) as $e | "\($n) nodes, \($e) edges"' graphify-out/graph.json 2>/dev/null)"
else
  soft "no graph yet — run: graphify update ."
fi

head_ "7. Ponytail"
if command -v claude >/dev/null 2>&1; then
  if claude plugin list 2>/dev/null | grep -q ponytail; then
    ok "ponytail plugin installed"
  else
    bad "ponytail not installed — claude plugin install ponytail@ponytail"
  fi
else
  soft "claude not on PATH, cannot check plugins"
fi

printf '\n\033[1m%d OK, %d FAIL, %d skipped\033[0m\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAIL" -eq 0 ]; then
  printf '\nEverything checks out. The last thing no script can test is the write\n'
  printf 'itself — start claude and ask it to save a note to memory.\n'
else
  printf '\nFix the FAIL lines above, then run this again.\n'
fi
exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)
