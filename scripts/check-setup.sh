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

head_ "4. Browser"
# patchright defaults to channel "chrome", i.e. the Chrome already installed on
# the machine; the downloaded chromium is only the fallback when that fails.
# Either one is enough, so only report trouble when neither is present.
SYS_CHROME=""
case "$(uname -s)" in
  Darwin)
    [ -d "/Applications/Google Chrome.app" ] && SYS_CHROME="/Applications/Google Chrome.app" ;;
  MINGW*|MSYS*|CYGWIN*)
    PF86="$(env | sed -n 's/^ProgramFiles(x86)=//p')"
    while IFS= read -r c; do
      [ -n "$c" ] && [ -f "$c" ] && { SYS_CHROME="$c"; break; }
    done <<EOF
${PROGRAMFILES:-}/Google/Chrome/Application/chrome.exe
${PF86:-}/Google/Chrome/Application/chrome.exe
${LOCALAPPDATA:-}/Google/Chrome/Application/chrome.exe
/c/Program Files/Google/Chrome/Application/chrome.exe
/c/Program Files (x86)/Google/Chrome/Application/chrome.exe
$HOME/AppData/Local/Google/Chrome/Application/chrome.exe
EOF
    ;;
  *)
    for c in google-chrome google-chrome-stable chromium chromium-browser; do
      command -v "$c" >/dev/null 2>&1 && { SYS_CHROME="$(command -v "$c")"; break; }
    done ;;
esac

BR="${PLAYWRIGHT_BROWSERS_PATH:-}"
if [ -z "$BR" ]; then
  case "$(uname -s)" in
    Darwin)               BR="$HOME/Library/Caches/ms-playwright" ;;
    MINGW*|MSYS*|CYGWIN*) BR="${LOCALAPPDATA:-$HOME/AppData/Local}/ms-playwright" ;;
    *)                    BR="${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright" ;;
  esac
fi
BUNDLED=""
ls -d "$BR"/chromium* >/dev/null 2>&1 && BUNDLED="$BR"

if [ -n "$SYS_CHROME" ]; then
  ok "system Chrome — $SYS_CHROME"
  [ -n "$BUNDLED" ] && ok "bundled chromium also available (fallback)" \
                    || soft "no bundled chromium fallback (only needed if Chrome fails to launch)"
elif [ -n "$BUNDLED" ]; then
  ok "bundled chromium — $BUNDLED"
else
  bad "no browser — install Google Chrome, or run: npx patchright install chromium"
fi

head_ "5. Google login"
# The package resolves its data dir with envPaths("notebooklm-mcp", {suffix:""}),
# which lands somewhere different on each OS — and the account switcher can nest
# the profile under accounts/<name>/. Resolve the root per platform, then look
# for any populated chrome_profile beneath it rather than one fixed path.
DATA="${NOTEBOOKLM_DATA_DIR:-}"
if [ -z "$DATA" ]; then
  case "$(uname -s)" in
    Darwin)               DATA="$HOME/Library/Application Support/notebooklm-mcp" ;;
    MINGW*|MSYS*|CYGWIN*) DATA="${LOCALAPPDATA:-$HOME/AppData/Local}/notebooklm-mcp/Data" ;;
    *)                    DATA="${XDG_DATA_HOME:-$HOME/.local/share}/notebooklm-mcp" ;;
  esac
fi
PROF=""
for d in $(find "$DATA" -maxdepth 3 -type d -name chrome_profile 2>/dev/null); do
  [ -n "$(ls -A "$d" 2>/dev/null)" ] && { PROF="$d"; break; }
done
if [ -n "$PROF" ]; then
  ok "profile directory present — $PROF"
  soft "whether the session is still valid: ask claude to run notebooklm get_health"
else
  bad "no profile — start claude and say: run setup_auth (looked under $DATA)"
fi

head_ "6. Hooks"
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

head_ "7. Graph"
if command -v graphify >/dev/null 2>&1 && [ -f graphify-out/graph.json ]; then
  ok "graph present — $(jq -r '(.nodes|length) as $n | (.links|length) as $e | "\($n) nodes, \($e) edges"' graphify-out/graph.json 2>/dev/null)"
else
  soft "no graph yet — run: graphify update ."
fi

head_ "8. Ponytail"
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
