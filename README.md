# 데이터베이스 8조 텀프로젝트

쿠팡이츠의 홈, 마이이츠(즐겨찾기 포함), 주문내역 화면을 구현한다. MySQL 스키마와 화면별 SQL, API 코드를 이 저장소에서 공유한다.

DB 스키마는 MySQL에서 생성과 제약조건을 확인했다. 샘플 데이터, 화면별 SQL, API 서버와 뷰는 작성 전이다.

## 공용 자료

- [Notion 프로젝트 홈](https://app.notion.com/p/40d3cd86f142803b9b56fd49db5599be)
- [역할 분담·보고서·발표](https://app.notion.com/p/4113cd86f14281b6bc6ec94d58bd1abd)
- [DB·API 구현 자료](https://app.notion.com/p/4113cd86f14281989808ee6b7daea80b)
- [공동 보고서](https://docs.google.com/document/d/1quy0ELbfUMO4LLlYho2nik5hC8uHYOEepcmDoTlnlcs/edit)
- [작업 계획](https://docs.google.com/document/d/18E7jaJEv43JHhhHHRuGolu_DX54voueo2YwH5gBFQUI)
- [회의 시간 입력](https://www.when2meet.com/?39622816-pPWgN)
- [DB 컬럼 사전](docs/db-column-dictionary.md)
- [ERD](docs/erd/README.md)
- [정규화 과정](docs/normalization.md)

## 역할

| 담당 | 맡은 작업 |
| --- | --- |
| PPT·발표 담당 | 앱·화면 분석, PPT 제작, 발표 |
| DB 담당 | MySQL·ERD·테이블 설계·샘플 데이터 |
| 홈 담당 | 홈 뷰·SQL·API |
| 마이이츠 담당 | 마이이츠·즐겨찾기 뷰·SQL·API |
| 주문내역 담당 | 주문내역 뷰·SQL·API |

## 폴더

- `db/`: 스키마, 샘플 데이터, 화면별 SQL
- `backend/`: 공통 API 서버 코드
- `postman/`: 요청 모음과 로컬 환경 파일
- `docs/`: API 명세, ERD, 정규화, 검증 기록
- `evidence/`: SQL·Postman·화면 캡처

## 작업 순서

1. 서버·뷰의 언어와 프레임워크, API 응답 형식을 정한다.
2. DB 담당이 스키마와 ERD를 팀원과 검토하고 샘플 데이터를 작성한다.
3. 각 화면 담당이 `db/queries/`의 SQL과 공통 `backend/`의 API, 해당 뷰를 구현한다.
4. MySQL 조회 결과, API의 JSON 응답, 화면 표시를 비교하고 정상·예외 요청을 확인한다.
5. 각자 공동 보고서에 맡은 부분을 작성하고 설명과 실행 캡처를 PPT·발표 담당에게 전달한다.
6. 대표 팀원 1명이 보고서를 취합·검수해 제출한다. 대표 제출자는 팀에서 정한다.

보고서는 테이블·정규화·SQL·API를 그렇게 구성한 이유와 실제 실행 결과를 설명한다. PPT는 발표 시간에 맞춰 핵심을 정리한다.

## 코드 공유

작업별로 브랜치를 나눠 수정한다. 브랜치 이름 예: `db/schema`, `feature/home`, `feature/my-page`, `feature/orders`, `docs/presentation`.

## 로컬 실행

DB 생성은 [MySQL 실행 안내](db/README.md)를 따른다. 서버 구현 후 설치·실행 명령과 MySQL 연결 방법을 [backend/README.md](backend/README.md)에 작성한다.

Postman에서 [Collection](postman/DB8.postman_collection.json)과 [DB8 Local 환경](postman/DB8-Local.postman_environment.json)을 가져오고, 활성 환경의 `baseUrl`을 자기 API 서버 주소로 설정한다. `http://localhost:3000`은 예시다. [설정 방법](postman/README.md)

DB 접속 정보는 `.env.example`을 복사한 로컬 `.env`에 입력한다. 실제 비밀번호와 토큰은 커밋하지 않는다. 샘플 데이터와 캡처에는 가상 데이터를 사용한다.
