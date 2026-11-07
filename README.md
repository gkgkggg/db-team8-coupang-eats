# 데이터베이스 8조 텀프로젝트

쿠팡이츠의 **홈 / 마이이츠(즐겨찾기 포함) / 주문내역** 3개 View를 위한 MySQL·SQL·API 공동 저장소입니다.

> 현재는 협업용 폴더와 명세 초안을 준비한 상태입니다. DB 스키마·API 서버는 아직 구현되지 않았습니다.

## 공용 자료
- [Notion 프로젝트 홈](https://app.notion.com/p/40d3cd86f142803b9b56fd49db5599be)
- [역할 분담·보고서·발표](https://app.notion.com/p/4113cd86f14281b6bc6ec94d58bd1abd)
- [DB·API 구현 자료](https://app.notion.com/p/4113cd86f14281989808ee6b7daea80b)
- [Google Docs 작업 계획](https://docs.google.com/document/d/18E7jaJEv43JHhhHHRuGolu_DX54voueo2YwH5gBFQUI)
- [회의 시간 입력](https://www.when2meet.com/?39622816-pPWgN)

## 역할
| 담당자 | 담당 |
| --- | --- |
| 김대용 | 앱·화면 분석, PPT 전체 제작, 발표 |
| 심영진 | MySQL·ERD·DB 설계·샘플 데이터 |
| 전지우 | 홈 SQL·API |
| 홍승민 | 마이이츠·즐겨찾기 SQL·API |
| 심동진 | 주문내역 SQL·API |

## 폴더
- `db/`: 스키마, 샘플 데이터, View별 SQL
- `backend/`: 공통 API 서버 코드 (언어·프레임워크 결정 후 추가)
- `postman/`: 팀 공용 Collection과 로컬 테스트 환경 예시
- `docs/`: API 명세, ERD, 실행·검증 기록
- `evidence/`: SQL·Postman 결과 캡처

## 개발 순서
1. API 서버 언어·프레임워크와 응답 규칙을 결정합니다.
2. 심영진이 `db/schema.sql`, `db/data.sql`, ERD를 작성하고 팀원과 검토합니다.
3. 각 View 담당자가 `db/queries/`와 같은 `backend/` 프로젝트에서 SQL·API를 구현합니다.
4. Postman으로 정상·예외 요청과 MySQL·JSON 결과의 일치를 확인합니다.
5. 담당 보고서용 설명·실행 결과를 김대용에게 전달합니다. 보고서 작성 방식은 11월 9일 교수님 질의 후 최종 확인합니다.

## 팀원 편집
비공개 저장소입니다. 팀원은 GitHub 아이디를 전달해 Collaborator 초대를 받은 뒤 수락해야 push할 수 있습니다. 현재 팀원 초대는 사용자의 요청으로 보류 중입니다.

권장 작업: `git pull` → 자기 작업 브랜치 → 수정·commit·push → Pull Request → 검토 후 병합. `main`에 force push하지 않습니다.

브랜치 예시: `db/schema`, `feature/home`, `feature/my-page`, `feature/orders`, `docs/presentation`.

## 실행 안내
아직 실행 가능한 API 서버가 없습니다. `backend/README.md`에 서버 실행법, `db/README.md`에 MySQL 실행 순서를 구현과 함께 작성합니다. Postman 요청 주소는 설계 예시입니다.

실제 DB 비밀번호·토큰은 commit하지 않고, `.env.example`을 복사한 로컬 `.env`에만 입력합니다. 샘플 데이터와 캡처는 가상 데이터를 사용합니다.
