---
name: commit-ko
description: 한글 커밋 메시지 작성 규칙. 사용자가 "커밋", "commit", "커밋해줘"라고 말하면 이 규칙대로 커밋 메시지를 작성한다.
---

# 한글 커밋 메시지 규칙

## 제목 형식

```
<타입>: <한글 요약>
```

- 50자 이내
- 명사형으로 종결 ("추가", "수정", "제거", "변경")
- 마침표 없음

## 타입

| 타입 | 용도 | 예시 |
|---|---|---|
| feat | 새 기능 | `feat: QR 코드 도트 셰이프 프리셋 추가` |
| fix | 버그 수정 | `fix: 로그인 후 화면 튕김 현상 수정` |
| refactor | 동작 변화 없는 구조 개선 | `refactor: QrResultProvider 상태 분리` |
| docs | 문서만 변경 | `docs: changelog 업데이트` |
| chore | 빌드/설정/잡일 | `chore: .gitignore 규칙 추가` |
| style | 포맷/공백 등 | `style: 들여쓰기 정리` |
| test | 테스트만 | `test: QrReadabilityService 단위 테스트 추가` |

## 본문 (선택)

- 제목과 빈 줄 1개 띄우기
- "왜" 바꿨는지 중심으로 서술 ("무엇"은 diff에 이미 있음)
- 줄바꿈은 72자 기준

## 예시 (좋음)

```
feat: QR 셰이프 탭에 사용자 프리셋 목록 노출

- UserShapePreset 엔티티를 QrShapeTab에 연동
- 삭제 버튼은 기본 프리셋에서는 숨김 처리
```

## 예시 (나쁨)

- `update` → 뭐 바꿨는지 없음
- `Fix bug.` → 영어 + 마침표 + 모호함
- `feat: 로그인 기능을 추가하였습니다.` → 서술형 + 마침표

## 실행 순서

1. `git status`로 변경 파일 확인
2. `git diff`로 실제 변경 내용 파악
3. 위 규칙에 맞춰 제목 작성
4. 필요하면 본문 추가
5. HEREDOC으로 `git commit -m` 실행
