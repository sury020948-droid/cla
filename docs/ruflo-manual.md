# ruflo 에이전트 활용 매뉴얼

다른 채팅(세션)에서 ruflo 에이전트들을 실제 작업에 쓰기 위한 안내서입니다.

---

## 0. 30초 요약

| 상황 | 해야 할 일 |
|---|---|
| **이 리포(cla)에서 새 채팅** | 첫 세션에 뜨는 신뢰 확인만 승인. 그 외 없음. |
| **다른 리포에서** | 그 리포 `.claude/settings.json`에 설정 블록 복사 (아래 2번) |

---

## 1. 먼저 — "에이전트 군단"의 실체

오해하기 쉬운 부분이라 먼저 짚습니다.

**여러 에이전트를 병렬로 돌리는 기능은 Claude Code에 원래부터 있습니다.** ruflo를
켜야 생기는 게 아닙니다. ruflo가 그 위에 얹어주는 건 이것들입니다:

| ruflo가 더해주는 것 | 구체적으로 |
|---|---|
| 미리 만들어진 에이전트 역할 | `coder`, `researcher`, `reviewer`, `witness-curator` (+ swarm 플러그인 설치 시 `architect`, `coordinator`) |
| 세션을 넘어가는 공유 메모리 | `memory_store` / `memory_search` 등 15개 도구 |
| 에이전트 장부와 비용 추적 | `agent_spawn` / `agent_list` / `agent_status` 등 9개 도구 |
| 스웜 조율 | `swarm_init` / `swarm_status` 등 6개 도구 |

정리하면 — **"여러 개 돌리는 건 원래 되고, ruflo는 그걸 기억하고 조율해준다."**

---

## 2. 다른 채팅에서 해야 할 일

### 케이스 A — 같은 리포(cla)에서 새 채팅을 열 때

1. PR #4가 머지되어 있는지 확인
2. 새 채팅을 연다
3. **플러그인 신뢰 확인 프롬프트가 뜨면 승인한다** (ruflo가 자체 훅과 MCP 서버를
   싣기 때문에 물어봅니다. 리포당 한 번)
4. 끝. `.claude/settings.json`이 커밋되어 있으므로 나머지는 자동입니다.

### 케이스 B — 다른 리포에서 쓸 때

그 리포의 `.claude/settings.json`에 아래를 넣고 커밋합니다. 파일이 없으면 새로 만드세요.

```json
{
  "enabledPlugins": {
    "ruflo-core@ruflo": true
  },
  "extraKnownMarketplaces": {
    "ruflo": {
      "source": {
        "source": "github",
        "repo": "ruvnet/ruflo",
        "sparsePaths": [".claude-plugin", "plugins"]
      }
    }
  }
}
```

> `sparsePaths`는 빼지 마세요. 이게 없으면 ruflo 저장소 전체(약 129MB)를 받습니다.
> 넣으면 약 21MB만 받습니다.

그리고 그 리포의 `.gitignore`에 아래를 추가하세요. ruflo CLI 명령을 돌리면 생기는
로컬 상태 파일들입니다.

```
.claude-flow/
.swarm/
.claude/proven-config.json
.claude/.proven-config-version
ruvector.db
```

### 선택 — 스웜 명령까지 원한다면

`/swarm`, `/watch` 명령과 `architect` / `coordinator` 에이전트가 필요하면 채팅에서
한 줄 실행하세요.

```
/plugin install ruflo-swarm@ruflo
```

---

## 3. 실제로 일 시키는 법

슬래시 명령을 외울 필요 없습니다. **하고 싶은 걸 평소 말투로 말하면** Claude가 알아서
맞는 에이전트와 도구를 고릅니다.

| 하고 싶은 것 | 이렇게 말하면 됩니다 |
|---|---|
| 설치 상태 점검 | "ruflo 상태 확인해줘" |
| 큰 작업을 여러 에이전트에 나눠 맡기기 | "이 작업을 에이전트 여러 개로 나눠서 병렬로 진행해줘" |
| 구현 전 선례 조사 | "researcher로 이 코드베이스에 비슷한 패턴 있는지 찾아줘" |
| 코드 리뷰 | "reviewer 에이전트로 지금 변경사항 검토해줘" |
| 결정사항 저장 | "이 아키텍처 결정을 ruflo 메모리에 저장해줘" |
| 저장한 내용 찾기 | "전에 저장한 인증 관련 결정 찾아줘" |
| 이 작업에 맞는 플러그인 찾기 | "이 작업에 맞는 ruflo 플러그인 추천해줘" |

### 병렬 작업을 시킬 때 요령

에이전트를 여럿 굴리는 건 **작업이 서로 독립적일 때** 효과가 있습니다.

- **잘 맞는 예** — "이 5개 모듈 각각에 테스트 붙여줘", "이 디렉토리 파일들 각각
  문서화해줘" (서로 안 겹침 → 동시에 진행 가능)
- **안 맞는 예** — "인증 기능 만들어줘" (앞 단계 결과가 뒤 단계 입력이라 순서대로
  해야 함 → 에이전트를 늘려도 빨라지지 않음)

---

## 4. 안 되는 것 / 미리 알아둘 것

여기가 제일 중요합니다. 모르면 헤맵니다.

### `agent_execute`는 작동하지 않습니다

ruflo의 `agent_execute` 도구는 `ANTHROPIC_API_KEY` 환경변수를 요구하는데, Claude Code는
인증을 내부적으로 관리하므로 이 키가 없습니다. **실제 에이전트 실행은 Claude Code 기본
Agent 기능으로 하시면 됩니다** — 그게 정상 경로입니다. ruflo의 `agent_*` 도구들은
장부/추적용으로 이해하세요.

### MCP 서버 첫 시작이 느립니다

새 세션에서 ruflo 도구가 바로 안 보일 수 있습니다. 서버가 `npx`로 패키지를 내려받아
시작하기 때문입니다(수십 초). **조급해하지 말고 잠깐 기다리세요.** 안 뜨면 "ruflo 상태
확인해줘"로 점검하면 됩니다.

### 메모리는 영구 저장이 아닙니다

`memory_store`로 저장한 내용은 `~/.claude/plugins/data/`에 들어갑니다. 이건 리포가 아니라
**실행 환경(컨테이너) 단위**입니다. 클라우드 세션은 일정 시간 뒤 컨테이너가 회수되므로
**그때 사라질 수 있습니다.**

> **꼭 남겨야 할 결정은 `memory_store` 대신 `CLAUDE.md`처럼 커밋되는 파일에 적으세요.**

### `npx ruflo init`은 이 리포에서 절대 실행하지 마세요

ruflo의 다른 설치 방식인데, 리포에 자체 `CLAUDE.md`와 `.claude/settings.json`, 훅,
helpers를 써넣습니다. 이 리포에 이미 설정된 graphify 훅과 skills 부트스트랩을
덮어씁니다. 지금 쓰는 플러그인 방식은 워크스페이스에 파일을 하나도 추가하지 않습니다.

### 플러그인을 무작정 늘리지 마세요

마켓플레이스에 35개가 있지만, 켤수록 매 세션 컨텍스트 비용이 붙습니다. 켜기 전에
비용을 확인하세요.

```
claude plugin details <플러그인이름>
```

`ruflo-core`는 상시 약 580토큰입니다. 또 `ruflo-knowledge-graph`는 이 리포가 이미 쓰는
graphify와 역할이 겹치므로 둘 중 하나만 쓰세요.

---

## 5. 문제가 생기면

| 증상 | 해결 |
|---|---|
| ruflo 도구가 안 보임 | 잠시 대기 후 "ruflo 상태 확인해줘". 그래도 없으면 세션 재시작 |
| 뭐가 잘못됐는지 모르겠음 | "ruflo doctor 돌려줘" — 진단 목록이 나옵니다 |
| `git status`에 모르는 파일이 잔뜩 | ruflo CLI가 만든 런타임 파일. 위 `.gitignore` 블록 추가 |
| 설치된 플러그인 확인 | `claude plugin list` |

`doctor`에서 아래 항목들이 경고로 나오는 건 **정상**입니다. `npx ruflo init`(CLI 방식)을
안 썼기 때문이고, 의도한 상태입니다.

- Config File / Daemon / Memory Database — 미초기화
- MCP Servers: No MCP config found
- Learning Bridge: auto-memory hook not installed
