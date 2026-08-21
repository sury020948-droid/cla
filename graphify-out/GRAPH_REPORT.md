# Graph Report - cla  (2026-08-21)

## Corpus Check
- 14 files · ~3,043 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 47 nodes · 39 edges · 11 communities (5 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `41c77f54`
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
- NotebookLM as persistent memory

## God Nodes (most connected - your core abstractions)
1. `NotebookLM as persistent memory` - 6 edges
2. `notebooklm` - 5 edges
3. `setup-notebooklm.sh script` - 4 edges
4. `memory-save` - 4 edges
5. `memory-recall` - 3 edges
6. `say()` - 2 edges
7. `warn()` - 2 edges
8. `die()` - 2 edges
9. `memory-common.sh script` - 1 edges
10. `memory-mark-dirty.sh script` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (11 total, 6 thin omitted)

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

### Community 10 - "NotebookLM as persistent memory"
Cohesion: 0.29
Nodes (6): How it fits together, Known constraints, NotebookLM as persistent memory, Rules of use, Setup, Whose account the notes land in

## Knowledge Gaps
- **21 isolated node(s):** `memory-common.sh script`, `memory-mark-dirty.sh script`, `memory-saved.sh script`, `memory-session-start.sh script`, `memory-stop-guard.sh script` (+16 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `memory-common.sh script`, `memory-mark-dirty.sh script`, `memory-saved.sh script` to the rest of the system?**
  _21 weakly-connected nodes found - possible documentation gaps or missing edges._