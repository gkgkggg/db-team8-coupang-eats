# MySQL 실행

담당: DB 담당. `schema.sql`은 DB와 테이블 구조를 생성하는 실행 파일입니다. `data.sql`과 화면별 SQL은 아직 작성 전입니다.

## 실행 방법

MySQL 8.0.16 이상에서 사용합니다. MySQL 8.4에서 검증했습니다.

1. MySQL Workbench에서 자신의 MySQL 서버에 접속합니다.
2. `schema.sql`을 SQL 편집기에서 엽니다.
3. 파일 전체를 실행합니다. `db_team8` 데이터베이스와 11개 테이블이 생성됩니다.
4. 왼쪽 SCHEMAS를 새로고침하고 `db_team8` → Tables를 펼칩니다.

명령줄에서는 MySQL에 접속한 뒤 실행합니다. 경로는 내려받은 파일 위치로 바꿉니다.

```sql
SOURCE C:/path/to/db-team8-coupang-eats/db/schema.sql;
```

생성 확인:

```sql
USE db_team8;
SHOW TABLES;
SHOW CREATE TABLE ReviewHelpful;
```

DB 이름은 `.env.example`과 같은 `db_team8`입니다. 다른 이름을 쓰려면 파일 앞의 CREATE DATABASE와 USE를 함께 수정합니다. 실행 계정에는 DB·테이블 생성 권한이 필요합니다.

## 생성되는 구조

- 11개 테이블·58개 컬럼·13개 외래키.
- 단일 ID 기본키 7개는 AUTO_INCREMENT, 생성 시각과 주문 시각은 CURRENT_TIMESTAMP를 기본값으로 사용합니다.
- 연결 테이블은 복합키로 같은 쌍의 중복을 막습니다. 카테고리 이름과 리뷰의 OrderID에는 UNIQUE를 둡니다.
- 금액은 0 이상, 수량은 1 이상, 별점은 1~5, Boolean 값은 0·1만 허용합니다. 주문 상태는 preparing / delivering / completed / cancelled입니다.
- 주소의 조건부 유일 인덱스로 사용자별 기본 주소를 최대 1개로 제한합니다. 기본 주소가 아닌 일반 주소는 여러 개 저장할 수 있습니다.
- ReviewHelpful.IsHelpful은 TRUE=도움이 돼요, FALSE=도움이 안 돼요입니다. 반응 취소는 행 삭제이며, 받은 도움 수는 TRUE만 집계합니다.
- 외래키의 기본 삭제 정책은 RESTRICT입니다. 리뷰를 삭제하면 해당 ReviewHelpful 행만 CASCADE로 삭제합니다.

`schema.sql`은 기존 테이블과 데이터를 삭제하지 않습니다. 이미 있는 테이블은 IF NOT EXISTS로 건너뛰므로, 기존 테이블을 최신 구조로 변경하는 용도로는 사용할 수 없습니다.

## 이후 작업

| 파일 | 내용 | 담당 |
| --- | --- | --- |
| data.sql | 가상 사용자·가게·메뉴·주문 데이터 입력 | DB 담당 |
| queries/home.sql | 주소·카테고리·가게 조회·검색·필터 | 홈 담당 |
| queries/my-page.sql | 사용자·리뷰·도움 수·즐겨찾기 조회 및 변경 | 마이이츠 담당 |
| queries/orders.sql | 주문 목록·상세·상태·금액·리뷰 여부 조회 | 주문내역 담당 |

샘플 데이터 작성 후 `schema.sql` → `data.sql` → 화면별 SQL 순서로 실행합니다. API에서는 한 주문의 가게와 메뉴 가게 일치, 주문당 메뉴 최소 1개, 주문 합계 대비 할인 한도, 완료 주문의 리뷰 작성 여부를 별도로 확인해야 합니다.

## 검증

2026-11-15, 별도 MySQL 8.4.13 환경에서 생성·재실행·제약조건 등 51개 검증을 통과했습니다. [검증 기록](../docs/verification.md) · [검증 결과](../docs/schema-validation.json)

참고: [MySQL CHECK](https://dev.mysql.com/doc/refman/8.4/en/create-table-check-constraints.html), [함수 인덱스](https://dev.mysql.com/doc/refman/8.4/en/create-index.html#functional-key-parts).
