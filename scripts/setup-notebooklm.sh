#!/usr/bin/env bash
# One-shot installer for the NotebookLM second-brain setup.
#
#   ./scripts/setup-notebooklm.sh "<NotebookLM notebook share URL>" ["<notebook name>"]
#
# Everything after this runs itself: the SessionStart hook injects the recall rule,
# the Stop hook refuses to let a session end without saving what it changed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NOTEBOOK_URL="${1:-}"
NOTEBOOK_NAME="${2:-Claude Memory}"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
# Anything that shells out to `claude` gets a ceiling: these are conveniences,
# never worth stalling the setup over.
bounded() { local s="$1"; shift; if command -v timeout >/dev/null 2>&1; then timeout "$s" "$@"; else "$@"; fi; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# --disable / --enable flip the switch without touching anything else.
case "$NOTEBOOK_URL" in
  --disable|--enable)
    CFG="$ROOT/.claude/memory.json"
    [ -f "$CFG" ] || die "No .claude/memory.json yet — nothing to toggle."
    VAL=$([ "$NOTEBOOK_URL" = "--enable" ] && echo true || echo false)
    jq --argjson v "$VAL" '.enabled = $v' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
    say "memory enabled=$VAL"
    exit 0
    ;;
esac

# 1. Prerequisites -----------------------------------------------------------
command -v node >/dev/null || die "Node.js is not installed. Install Node 18+ first."
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" -ge 18 ] || die "Node 18+ required, found $(node -v)."
command -v npx >/dev/null || die "npx not found (comes with npm)."
command -v jq  >/dev/null || die "jq not found. Install it (brew install jq / apt install jq)."
say "Node $(node -v), npx and jq present."

# 2. MCP server ---------------------------------------------------------------
# No prefetch here. notebooklm-mcp does not implement --version, so `npx ...
# --version` starts the stdio server instead of printing anything and then
# blocks on stdin forever. Claude Code fetches the package on first use anyway.
say "notebooklm-mcp will be fetched automatically on first use."

# 3. Register the server with Claude Code -----------------------------------
# .mcp.json in the repo already declares it project-wide. Registering with the
# CLI too makes it available outside this directory and is harmless if it exists.
if command -v claude >/dev/null; then
  if bounded 60 claude mcp list 2>/dev/null | grep -q '^notebooklm'; then
    say "MCP server 'notebooklm' already registered."
  else
    say "Registering MCP server with Claude Code..."
    bounded 60 claude mcp add notebooklm -- npx notebooklm-mcp@latest \
      || warn "claude mcp add failed; .mcp.json in this repo still covers this project."
  fi
else
  warn "claude CLI not on PATH. .mcp.json covers this project; run 'claude mcp add notebooklm -- npx notebooklm-mcp@latest' elsewhere."
fi

# 4. Write the project memory config ----------------------------------------
if [ -z "$NOTEBOOK_URL" ]; then
  cat <<'EOF'

Next: create the notebook, then re-run this script with its URL.

  1. Open https://notebooklm.google.com
  2. "Create new" -> name it "Claude Memory"
  3. Add any one starter source (a text note saying "Claude Memory notebook" is enough;
     NotebookLM needs at least one source before it will answer questions)
  4. Copy the notebook URL from the address bar
  5. Re-run:  ./scripts/setup-notebooklm.sh "<that URL>"

EOF
  exit 0
fi

# Google answers on both hosts, and a browser may well show the shorter one.
# The MCP server only knows the canonical host, so take either and normalise.
case "$NOTEBOOK_URL" in
  https://notebooklm.google.com/notebook/*|https://notebook.google.com/notebook/*) ;;
  *) die "Expected https://notebooklm.google.com/notebook/<id>, got: $NOTEBOOK_URL" ;;
esac

NOTEBOOK_ID="${NOTEBOOK_URL##*/notebook/}"
NOTEBOOK_ID="${NOTEBOOK_ID%%\?*}"
NOTEBOOK_URL="https://notebooklm.google.com/notebook/$NOTEBOOK_ID"

jq -n \
  --arg url  "$NOTEBOOK_URL" \
  --arg id   "$NOTEBOOK_ID" \
  --arg name "$NOTEBOOK_NAME" \
  '{enabled: true, notebook_name: $name, notebook_id: $id, notebook_url: $url}' \
  > "$ROOT/.claude/memory.json"
say "Wrote .claude/memory.json -> $NOTEBOOK_NAME"

# 5. Auth ---------------------------------------------------------------------
AUTH_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/notebooklm-mcp/chrome_profile"
[ "$(uname)" = "Darwin" ] && AUTH_DIR="$HOME/Library/Application Support/notebooklm-mcp/chrome_profile"

if [ -d "$AUTH_DIR" ]; then
  say "Google login already stored ($AUTH_DIR)."
else
  cat <<'EOF'

One manual step is left — the Google login. It opens a real Chrome window, so it
cannot be scripted:

  Start Claude Code in this directory and say:  "run setup_auth"

A Chrome window opens; log in to the Google account that owns the notebook. The
session is stored in a persistent Chrome profile, so this happens exactly once.
(Headless server? run it under xvfb: xvfb-run -a npx notebooklm-mcp@latest)

EOF
fi

cat <<EOF

Setup complete. From here it runs on its own:

  - session start  -> Claude is told to consult "$NOTEBOOK_NAME" for past context
  - session end    -> if the session changed anything, the Stop hook makes Claude
                      write a summary into the notebook before it can finish
  - "what did we decide about X?" -> memory-recall skill queries the notebook

Turn it off any time:  ./scripts/setup-notebooklm.sh --disable
EOF
