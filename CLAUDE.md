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

## VFF (value-for-fable) — 상시 가동 중

[value-for-fable](https://github.com/itsinseong/value-for-fable)을 `.claude/` 아래에
벤더링해 커밋했다. 코드가 아니라 프롬프트 묶음이고, Sonnet 세션에 Fable 5의 운영 구조
(결론 첫 문장, 측정 먼저 좁히기, 완료 선언 전 검증)를 입힌다.

| 구성 요소 | 경로 | 역할 |
| --- | --- | --- |
| Output style | `.claude/output-styles/vff-v2.md` | **상시 모드.** `settings.json`의 `outputStyle: "VFF v2"`로 켜져 있다 |
| Output style v1 | `.claude/output-styles/vff.md` | 원본 보존용. 저자 재검증에서 v2보다 10.9점 낮다 |
| Skill | `.claude/skills/itsvff/SKILL.md` | 수동 발동 모드. "VFF"·"패블 모드"로 트리거 |
| Agent | `.claude/agents/itsvff.md` | 위임 전용 서브에이전트 (`model: sonnet` 고정) |
| Hook | `.claude/hooks/vff-reminder.sh` | transcript 400KB 초과 시에만 드리프트 리마인더 주입 |

Rules:
- 상시 모드는 `.claude/settings.json`의 `outputStyle`로 켜고 끈다. 끄려면 그 값을
  `"default"`로 바꾸거나 키를 지운다 — 다음 세션부터 적용된다. `/config` → Output style
  로도 같은 일을 할 수 있지만, 그건 `.claude/settings.local.json`에 쓰이므로 커밋된
  설정을 덮는다는 점만 알아둘 것.
- **상시 모드는 output style이라 시스템 프롬프트를 직접 바꾼다.** 이 레포는
  `keep-coding-instructions: true`를 켜 둬서 Claude Code 내장 코딩 지침이 유지된다.
  이 플래그를 지우면 변경 범위 잡기·주석 규약·작업 검증 지침이 통째로 빠진다.
- VFF는 명시적으로 **Sonnet 전용**이다. 비용 이점은 `/model sonnet`과 함께 쓸 때만
  나온다. Opus 세션에서는 품질 손해도 이득도 크지 않지만 절감 효과가 없다.
- `.claude/skills/itsvff/` 파일은 손으로 고치지 말 것 — 벤더링된 복사본이다. 출처,
  상류 커밋, 상류 대비 변경 두 건은 `.claude/skills/itsvff/UPSTREAM.md`에 기록돼 있다.
  상류는 AGPL-3.0-or-later이고 `LICENSE`·`NOTICE`를 함께 벤더링했다.
- 머신 전역(`~/.claude`) 설치는 `scripts/setup-skills.sh`가 처리한다. 이미 있는 파일과
  이미 설정된 `outputStyle`은 절대 덮어쓰지 않는다.
