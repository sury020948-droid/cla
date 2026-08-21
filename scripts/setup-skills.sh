#!/usr/bin/env bash
# Idempotent bootstrap for the Claude Code skills this repo depends on.
#
# Safe to re-run: every step checks for an existing install first and skips it.
# Nothing here overwrites or deletes files that are already present.
#
#   bash scripts/setup-skills.sh          # provision anything missing
#   bash scripts/setup-skills.sh --check  # report status only, install nothing
#
# Project-level skills live in .claude/skills/ and are committed, so they are
# already available in any clone without running this. What this script adds is
# the *machine-level* half: the same four skills under ~/.claude/skills so they
# apply in every project on this device, plus GSD, which only installs globally,
# plus VFF (value-for-fable) — its skill, agent, output styles and reminder hook
# copied out of .claude/ so the always-on style is on in every project too.

set -uo pipefail

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
GLOBAL_SKILLS="$CLAUDE_HOME/skills"

MIN_NODE_MAJOR=22
MIN_NODE_MINOR=20

missing=0
installed_now=0

log()  { printf '  %s\n' "$*"; }
ok()   { printf '  [ok]   %s\n' "$*"; }
add()  { printf '  [add]  %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }

# --- node version gate -------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
  warn "node not found on PATH; install Node ${MIN_NODE_MAJOR}.${MIN_NODE_MINOR}+ first"
  exit 1
fi

node_raw="$(node --version)"          # e.g. v22.22.2
node_ver="${node_raw#v}"
node_major="${node_ver%%.*}"
node_rest="${node_ver#*.}"
node_minor="${node_rest%%.*}"

if [ "$node_major" -lt "$MIN_NODE_MAJOR" ] ||
   { [ "$node_major" -eq "$MIN_NODE_MAJOR" ] && [ "$node_minor" -lt "$MIN_NODE_MINOR" ]; }; then
  warn "node $node_raw is below the required ${MIN_NODE_MAJOR}.${MIN_NODE_MINOR}; skills may fail to install"
  exit 1
fi
ok "node $node_raw"

# --- the four skills ---------------------------------------------------------
# name|source|extra args
SKILLS="
agent-browser|vercel-labs/agent-browser|
find-skills|vercel-labs/skills|--skill find-skills
design-taste-frontend|https://github.com/Leonxlnx/taste-skill|--skill design-taste-frontend
mcp-builder|anthropics/skills|--skill mcp-builder
"

install_skill_global() {
  local name="$1" source="$2" extra="$3"
  if [ -f "$GLOBAL_SKILLS/$name/SKILL.md" ]; then
    ok "$name (global)"
    return 0
  fi
  missing=$((missing + 1))
  if [ "$CHECK_ONLY" -eq 1 ]; then
    add "$name (global) — not installed"
    return 0
  fi
  add "installing $name globally..."
  # shellcheck disable=SC2086
  if npx --yes skills@latest add "$source" $extra --agent claude-code --yes --copy --global </dev/null >/dev/null 2>&1 &&
     [ -f "$GLOBAL_SKILLS/$name/SKILL.md" ]; then
    ok "$name (global) installed"
    installed_now=$((installed_now + 1))
  else
    warn "$name (global) install failed — check network access to github.com / registry.npmjs.org"
  fi
}

echo "Claude Code skills bootstrap"
echo "  repo:   $REPO_ROOT"
echo "  global: $GLOBAL_SKILLS"
echo

echo "project skills (committed, no install needed):"
printf '%s\n' "$SKILLS" | while IFS='|' read -r name source extra; do
  [ -z "$name" ] && continue
  if [ -f "$REPO_ROOT/.claude/skills/$name/SKILL.md" ]; then
    ok "$name"
  else
    warn "$name missing from .claude/skills — run: npx --yes skills@latest experimental_install"
  fi
done
echo

echo "global skills (this machine, all projects):"
while IFS='|' read -r name source extra; do
  [ -z "$name" ] && continue
  install_skill_global "$name" "$source" "$extra"
done <<EOF
$SKILLS
EOF
echo

# --- GSD ---------------------------------------------------------------------
# GSD installs globally only. v1.11.0+ ships gsd-* entries under ~/.claude/skills
# rather than the older ~/.claude/commands/gsd-help.md layout, so probe both.
echo "GSD (global only):"
if [ -f "$GLOBAL_SKILLS/gsd-help/SKILL.md" ] || [ -f "$CLAUDE_HOME/commands/gsd-help.md" ]; then
  gsd_ver="$(cat "$CLAUDE_HOME/gsd-core/VERSION" 2>/dev/null || echo "unknown")"
  ok "gsd-core $gsd_ver"
else
  missing=$((missing + 1))
  if [ "$CHECK_ONLY" -eq 1 ]; then
    add "gsd-core — not installed"
  else
    add "installing gsd-core globally..."
    if npx --yes @opengsd/gsd-core@latest --claude --global </dev/null >/dev/null 2>&1 &&
       [ -f "$GLOBAL_SKILLS/gsd-help/SKILL.md" ]; then
      ok "gsd-core installed"
      installed_now=$((installed_now + 1))
    else
      warn "gsd-core install failed — check network access to registry.npmjs.org"
    fi
  fi
fi
echo

# --- VFF (value-for-fable) ---------------------------------------------------
# VFF is vendored under .claude/ and committed, so it already loads inside this
# repo. What this adds is the machine-level half: the same files under ~/.claude
# so VFF applies in every project on this device, plus the always-on output
# style switched on in the global settings.
#
# Upstream is github.com/itsinseong/value-for-fable (AGPL-3.0-or-later). The
# provenance and the two deltas we carry are recorded in
# .claude/skills/itsvff/UPSTREAM.md.
echo "VFF / value-for-fable (global):"

# Copies one repo path to the same-named spot under ~/.claude, never over an
# existing file — consistent with the rest of this script.
copy_if_absent() {
  src="$REPO_ROOT/$1"
  dst="$CLAUDE_HOME/$2"
  label="$2"
  if [ -e "$dst" ]; then
    ok "$label"
    return 0
  fi
  if [ ! -e "$src" ]; then
    warn "$label — missing from the repo at $1"
    return 0
  fi
  missing=$((missing + 1))
  if [ "$CHECK_ONLY" -eq 1 ]; then
    add "$label — not installed"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if cp -R "$src" "$dst"; then
    ok "$label installed"
    installed_now=$((installed_now + 1))
  else
    warn "$label — copy failed"
  fi
}

copy_if_absent ".claude/skills/itsvff"           "skills/itsvff"
copy_if_absent ".claude/agents/itsvff.md"        "agents/itsvff.md"
copy_if_absent ".claude/output-styles/vff.md"    "output-styles/vff.md"
copy_if_absent ".claude/output-styles/vff-v2.md" "output-styles/vff-v2.md"
copy_if_absent ".claude/hooks/vff-reminder.sh"   "hooks/vff-reminder.sh"
[ -f "$CLAUDE_HOME/hooks/vff-reminder.sh" ] && chmod +x "$CLAUDE_HOME/hooks/vff-reminder.sh"

# Global settings: turn the always-on style on and register the drift-reminder
# hook. Both edits are additive — an outputStyle that is already set (to
# anything, including a different style you chose on purpose) is never
# replaced, and the hook is appended only when no vff-reminder entry exists.
if ! command -v python3 >/dev/null 2>&1; then
  warn "python3 not found — skipping the global settings edit"
  log "set \"outputStyle\": \"VFF v2\" in $CLAUDE_HOME/settings.json by hand"
else
  settings_mode=apply
  [ "$CHECK_ONLY" -eq 1 ] && settings_mode=check
  python3 - "$CLAUDE_HOME/settings.json" "$settings_mode" "$CLAUDE_HOME/hooks/vff-reminder.sh" <<'PY'
import json, os, sys

path, mode, hook_path = sys.argv[1], sys.argv[2], sys.argv[3]

try:
    data = json.load(open(path)) if os.path.exists(path) else {}
except (ValueError, OSError) as exc:
    print("  [warn] %s is unreadable (%s) — leaving it alone" % (path, exc))
    raise SystemExit(0)

if not isinstance(data, dict):
    print("  [warn] %s is not a JSON object — leaving it alone" % path)
    raise SystemExit(0)

pending = []

current_style = data.get("outputStyle")
if current_style is None:
    pending.append('outputStyle="VFF v2"')
elif current_style != "VFF v2":
    print("  [ok]   outputStyle is already %r — left as is" % current_style)

hooks = data.get("hooks")
if not isinstance(hooks, dict):
    hooks = {}
submit = hooks.get("UserPromptSubmit")
if not isinstance(submit, list):
    submit = []
hook_registered = "vff-reminder.sh" in json.dumps(submit)
if not hook_registered:
    pending.append("UserPromptSubmit reminder hook")

if not pending:
    print("  [ok]   global settings already carry VFF")
    raise SystemExit(0)

if mode == "check":
    print("  [add]  global settings — %s" % ", ".join(pending))
    raise SystemExit(3)

if current_style is None:
    data["outputStyle"] = "VFF v2"
if not hook_registered:
    submit.append({
        "hooks": [
            {"type": "command", "command": 'bash "%s"' % hook_path, "timeout": 10}
        ]
    })
    hooks["UserPromptSubmit"] = submit
    data["hooks"] = hooks

os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
tmp = path + ".vff-tmp"
with open(tmp, "w") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
os.replace(tmp, path)
print("  [add]  global settings — %s" % ", ".join(pending))
raise SystemExit(4)
PY
  settings_rc=$?
  [ "$settings_rc" -eq 3 ] && missing=$((missing + 1))
  [ "$settings_rc" -eq 4 ] && installed_now=$((installed_now + 1))
fi
echo

# --- agent-browser CLI (optional companion) ----------------------------------
echo "agent-browser CLI (optional):"
if command -v agent-browser >/dev/null 2>&1; then
  ok "$(agent-browser --version 2>/dev/null || echo 'agent-browser present')"
  if [ -n "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ]; then
    log "using AGENT_BROWSER_EXECUTABLE_PATH=$AGENT_BROWSER_EXECUTABLE_PATH"
  else
    log "run 'agent-browser install' once to download Chrome, or set"
    log "AGENT_BROWSER_EXECUTABLE_PATH to an existing Chrome/Chromium binary"
  fi
else
  log "not installed (skipped — it is optional)"
  log "to add it: npm install -g agent-browser && agent-browser install"
fi
echo

if [ "$CHECK_ONLY" -eq 1 ]; then
  if [ "$missing" -eq 0 ]; then
    echo "All set — nothing to install."
  else
    echo "$missing item(s) not installed. Run: bash scripts/setup-skills.sh"
  fi
  exit 0
fi

if [ "$installed_now" -gt 0 ]; then
  echo "Installed $installed_now item(s). Restart Claude Code to pick them up."
else
  echo "Nothing to do — everything was already installed."
fi
