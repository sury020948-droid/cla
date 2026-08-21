## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## skills

Four skills are vendored in `.claude/skills/` and committed, so they load automatically
in any clone of this repo — no install step. `skills-lock.json` pins their sources.

| Skill | Use it for |
| --- | --- |
| `agent-browser` | Driving a real browser: open pages, click, fill forms, screenshot, verify UI |
| `find-skills` | Finding and installing a skill for something not covered here |
| `design-taste-frontend` | Frontend work that should not look templated |
| `mcp-builder` | Writing an MCP server to connect an external service |

GSD (`@opengsd/gsd-core`) has no project-level install — it lives in `~/.claude`
and provides the `gsd-*` skills for multi-step planning.

Rules:
- At the start of a session, if `~/.claude/skills/` is missing any of the four skills
  above or `gsd-help`, run `bash scripts/setup-skills.sh` to provision this machine.
  It is idempotent, skips whatever is already installed, and overwrites nothing.
  `bash scripts/setup-skills.sh --check` reports status without installing.
- Do not edit files under `.claude/skills/` by hand — they are vendored copies.
  Update them with `npx --yes skills@latest update`, which refreshes `skills-lock.json`.
- `agent-browser` needs a Chrome binary. `agent-browser install` downloads one; where
  that download is blocked, point `AGENT_BROWSER_EXECUTABLE_PATH` at an existing
  Chrome/Chromium instead.
