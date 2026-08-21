# value-for-fable (VFF) — 벤더링 기록

이 레포에 들어온 VFF 파일들의 출처와 상류 대비 변경점을 남긴다.
`.claude/skills/` 아래 다른 스킬과 마찬가지로 커밋되어 있어, 이 레포의 어떤 클론에서도
설치 단계 없이 로드된다.

## 출처

- 상류: https://github.com/itsinseong/value-for-fable
- 저자: itsinseong
- 벤더링 시점 상류 커밋: `afbfff6e63fb48b133be68fb8ddff254df01dbaf` (plugin.json 기준 v1.0.1)
- 라이선스: AGPL-3.0-or-later (`LICENSE`, `NOTICE` 동봉)
- 벤더링 방식: 상류 README의 "방법 2 — 수동 설치" 경로.
  `/plugin marketplace add`를 쓰지 않았으므로 플러그인 업데이트도 자동으로 오지 않는다.
  갱신하려면 상류를 다시 클론해 아래 파일들을 덮어쓰고, "상류 대비 변경점"을 다시 적용한다.

## 벤더링된 파일

| 이 레포 경로 | 상류 경로 |
| --- | --- |
| `.claude/skills/itsvff/SKILL.md` | `skills/itsvff/SKILL.md` |
| `.claude/agents/itsvff.md` | `agents/itsvff.md` |
| `.claude/output-styles/vff.md` | `output-styles/vff.md` |
| `.claude/output-styles/vff-v2.md` | `output-styles/vff-v2.md` |
| `.claude/hooks/vff-reminder.sh` | `hooks/reminder.sh` |
| `.claude/skills/itsvff/LICENSE` | `LICENSE` |
| `.claude/skills/itsvff/NOTICE` | `NOTICE` |

`bench/`(벤치 하네스·원자료)와 `.claude-plugin/`(플러그인 매니페스트)은 런타임에 쓰이지
않으므로 가져오지 않았다. 근거 자료가 필요하면 상류 `bench/RESULTS.md`를 본다.

## 상류 대비 변경점

두 곳을 고쳤다. 둘 다 **상시(always-on) 모드로 운영하기 위해 필요한 수정**이고,
상류의 수동 발동(스킬) 모드 동작은 바꾸지 않는다.

### 1. `output-styles/vff-v2.md` — `keep-coding-instructions: true` 추가

Claude Code의 custom output style은 이 값이 `true`가 아니면 내장 소프트웨어 엔지니어링
지침(변경 범위 잡기, 주석 규약, 작업 검증)을 시스템 프롬프트에서 **제외한다**. 기본값은
`false`다. (출처: code.claude.com/docs/en/output-styles)

상류 v1(`vff.md`)에는 이 플래그가 있지만 저자가 권장하는 v2에는 없다. v2를 코딩 레포에서
상시로 켜면 내장 코딩 지침이 통째로 빠지고 v2 자체의 `<code_and_changes>` 섹션(상류보다
얇다)만 남는다. 상류 벤치는 진단·조언·작문 과제 기준이라 이 손실이 측정된 적이 없어,
보수적인 쪽을 택해 플래그를 켰다.

되돌리려면 `vff-v2.md` frontmatter에서 `keep-coding-instructions: true` 한 줄을 지운다.

### 2. `hooks/reminder.sh` — 상시 모드 감지 정규식에 ` v2` 허용

상류 훅은 `"outputStyle"`이 `vff` 또는 `value-for-fable:vff`일 때만 상시 모드로 인식한다.
그런데 v2의 스타일 이름은 `VFF v2`라 매칭에 실패하고, 그러면 transcript에서 `VFF 적용`
마커를 찾는 경로로 빠지는데 상시 모드에서는 그 마커가 찍히지 않는다. 결과적으로 **v2 상시
모드에서는 드리프트 방지 리마인더가 한 번도 주입되지 않는다.**

정규식에 ` v2`를 선택적으로 붙여 `VFF v2`도 상시 모드로 인식하게 했다. 훅의 나머지 동작
(400KB 임계값, 조건 불충족 시 침묵)은 그대로다.
