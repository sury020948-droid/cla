---
name: memory-save
description: Write this session's decisions and context into the NotebookLM memory notebook so a future session can recall them. Use at the end of a session that changed code, made a decision, or discovered something worth keeping, and whenever the Stop hook reports "Unsaved session memory". Do not use for reading past memory — that is memory-recall.
allowed-tools: Bash, mcp__notebooklm__add_source, mcp__notebooklm__list_notebooks, mcp__notebooklm__select_notebook, mcp__notebooklm__get_health
---

# memory-save

Append a session record to the NotebookLM notebook configured in `.claude/memory.json`.

## Steps

1. Read the config:

   ```bash
   cat .claude/memory.json
   ```

   `notebook_url` is the target. If the file is missing, memory is not set up yet —
   tell the user to run `scripts/setup-notebooklm.sh` and stop.

2. Make sure that notebook is the active one (only needed once per session):

   ```
   select_notebook(id: <id from .claude/memory.json>)
   ```

   If `select_notebook` fails because the library is empty, call `list_notebooks` first;
   if it is still missing, the setup script was never run — say so and stop.

3. Write the record with `add_source`:

   ```
   add_source(
     notebook_url: <notebook_url>,
     type: "text",
     content: <the record below>
   )
   ```

4. Confirm the write succeeded (the tool returns source counts before/after — the count
   must have gone up), then mark the session saved so the Stop hook lets go:

   ```bash
   .claude/hooks/memory-saved.sh "<session_id>"
   ```

   The session id is in the Stop hook message. If you got here without one, use
   `$CLAUDE_SESSION_ID` if it is set, otherwise skip this step.

5. Tell the user in one line what was saved. Do not paste the whole record back.

## Record format

Keep it dense and factual. Someone reading this in three months with zero context should
understand what happened and why. No filler, no restating the format itself.

```
# <YYYY-MM-DD> — <project name> — <5-8 word title>

## Asked
<what the user wanted, one or two lines>

## Done
- <change, with file paths>
- <change, with file paths>

## Decisions
- <decision> — because <reason>. Alternatives rejected: <alternative + why>.

## Gotchas
- <anything surprising: a failure mode, an environment quirk, a wrong assumption>

## Open
- <unfinished work, known bug, next step>

## Keywords
<comma-separated terms a future session would actually search for>
```

## Rules

- One record per session. If a save already happened this session and more work followed,
  save a second record covering only the new work.
- Never write secrets, tokens, keys, passwords, or full `.env` contents into the notebook.
  Reference them by name (`DATABASE_URL is set in .env`), never by value.
- Skip the save entirely for a session that only read or answered questions — there is
  nothing to remember. Mark it saved anyway so the Stop hook does not nag.
- If `add_source` fails, say so plainly and do not write the saved marker. A silent
  failure is worse than a noisy one: the memory would look present but be empty.
