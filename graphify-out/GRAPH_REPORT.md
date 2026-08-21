# Graph Report - cla  (2026-08-21)

## Corpus Check
- 13 files · ~2,470 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 39 nodes · 32 edges · 10 communities (4 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `88272158`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- CLAUDE.md
- memory-common.sh
- notebooklm
- memory-save
- setup-notebooklm.sh
- memory-recall
- memory-mark-dirty.sh
- memory-saved.sh
- memory-session-start.sh
- memory-stop-guard.sh

## God Nodes (most connected - your core abstractions)
1. `notebooklm` - 5 edges
2. `setup-notebooklm.sh script` - 4 edges
3. `memory-save` - 4 edges
4. `memory-recall` - 3 edges
5. `say()` - 2 edges
6. `warn()` - 2 edges
7. `die()` - 2 edges
8. `memory-common.sh script` - 1 edges
9. `memory-mark-dirty.sh script` - 1 edges
10. `memory-saved.sh script` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (10 total, 6 thin omitted)

### Community 2 - "notebooklm"
Cohesion: 0.33
Nodes (5): HEADLESS, NOTEBOOKLM_DISABLED_TOOLS, NOTEBOOKLM_PROFILE, npx, notebooklm

### Community 3 - "memory-save"
Cohesion: 0.40
Nodes (4): memory-save, Record format, Rules, Steps

### Community 4 - "setup-notebooklm.sh"
Cohesion: 0.70
Nodes (4): die(), say(), setup-notebooklm.sh script, warn()

### Community 5 - "memory-recall"
Cohesion: 0.50
Nodes (3): memory-recall, Rules, Steps

## Knowledge Gaps
- **16 isolated node(s):** `memory-common.sh script`, `memory-mark-dirty.sh script`, `memory-saved.sh script`, `memory-session-start.sh script`, `memory-stop-guard.sh script` (+11 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `memory-common.sh script`, `memory-mark-dirty.sh script`, `memory-saved.sh script` to the rest of the system?**
  _16 weakly-connected nodes found - possible documentation gaps or missing edges._