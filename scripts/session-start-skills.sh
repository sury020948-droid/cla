#!/usr/bin/env bash
# SessionStart hook — keeps this machine provisioned with no manual step.
#
# The four skills in .claude/skills/ are committed, so they already load in any
# clone of this repo. This hook covers the machine-level half: the same skills
# under ~/.claude/skills (so they apply in *every* project on this device) plus
# GSD, which has no project-level install.
#
# It never blocks session start. When everything is present it exits in a few
# milliseconds without spawning node; when something is missing it hands the
# work to scripts/setup-skills.sh in the background and returns immediately.
# Set CLA_SKIP_SKILL_BOOTSTRAP=1 to disable it entirely.

set -uo pipefail

[ "${CLA_SKIP_SKILL_BOOTSTRAP:-}" = "1" ] && exit 0

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
GLOBAL_SKILLS="$CLAUDE_HOME/skills"
SETUP="$REPO_ROOT/scripts/setup-skills.sh"
LOG="$CLAUDE_HOME/skills-bootstrap.log"

[ -f "$SETUP" ] || exit 0

# Fast path: pure-bash presence check, no subprocess.
needs_setup=0
for name in agent-browser find-skills design-taste-frontend mcp-builder; do
  [ -f "$GLOBAL_SKILLS/$name/SKILL.md" ] || needs_setup=1
done
if [ ! -f "$GLOBAL_SKILLS/gsd-help/SKILL.md" ] && [ ! -f "$CLAUDE_HOME/commands/gsd-help.md" ]; then
  needs_setup=1
fi

[ "$needs_setup" -eq 0 ] && exit 0

# A previous session may already be provisioning; don't stack installs.
LOCK="$CLAUDE_HOME/.skills-bootstrap.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  # Clear a lock left behind by a crashed run (older than 30 minutes).
  if [ -z "$(find "$LOCK" -maxdepth 0 -mmin -30 2>/dev/null)" ]; then
    rmdir "$LOCK" 2>/dev/null && mkdir "$LOCK" 2>/dev/null || exit 0
  else
    exit 0
  fi
fi

mkdir -p "$CLAUDE_HOME"
nohup bash -c 'bash "$1" >>"$2" 2>&1; rmdir "$3" 2>/dev/null' _ "$SETUP" "$LOG" "$LOCK" \
  </dev/null >/dev/null 2>&1 &
disown 2>/dev/null

echo "Provisioning machine-level Claude Code skills in the background (log: $LOG)."
echo "They become available after the next restart; this session is unaffected."
exit 0
