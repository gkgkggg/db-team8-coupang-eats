# MySQL 실행

담당: DB 담당. `schema.sql`로 DB와 테이블을 생성하고 `data.sql`로 샘플 데이터를 입력한다. 화면별 SQL은 작성 전이다.

## 실행 방법

MySQL 8.0.16 이상에서 사용한다. MySQL 8.4에서 검증했다.

1. MySQL Workbench에서 자신의 MySQL 서버에 접속한다.
2. `schema.sql`을 SQL 편집기에서 연다.
3. 파일 전체를 실행한다. `db_team8` 데이터베이스와 11개 테이블이 생성된다.
4. 왼쪽 SCHEMAS를 새로고침하고 `db_team8` → Tables를 펼친다.

명령줄에서는 MySQL에 접속한 뒤 실행한다. 경로는 내려받은 파일 위치로 바꾼다.

```sql
SOURCE C:/path/to/db-team8-coupang-eats/db/schema.sql;
```

생성 확인:

```sql
USE db_team8;
SHOW TABLES;
SHOW CREATE TABLE ReviewHelpful;
```

DB 이름은 `.env.example`과 같은 `db_team8`이다. 다른 이름을 쓰려면 파일 앞의 CREATE DATABASE와 USE를 함께 수정한다. 실행 계정에는 DB·테이블 생성 권한이 필요하다.

## 생성되는 구조

- 11개 테이블·58개 컬럼·13개 외래키.
- 단일 ID 기본키 7개는 AUTO_INCREMENT, 생성 시각과 주문 시각은 CURRENT_TIMESTAMP를 기본값으로 사용한다.
- 연결 테이블은 복합키로 같은 쌍의 중복을 막는다. 카테고리 이름과 리뷰의 OrderID에는 UNIQUE를 둔다.
- 금액은 0 이상, 수량은 1 이상, 별점은 1~5, Boolean 값은 0·1만 허용한다. 주문 상태는 preparing / delivering / completed / cancelled다.
- 주소의 조건부 유일 인덱스로 사용자별 기본 주소를 최대 1개로 제한한다. 기본 주소가 아닌 일반 주소는 여러 개 저장할 수 있다.
- ReviewHelpful.IsHelpful은 TRUE=도움이 돼요, FALSE=도움이 안 돼요다. 반응을 취소하면 행을 삭제한다. 받은 도움 수는 TRUE만 집계한다.
- 외래키의 기본 삭제 정책은 RESTRICT다. 리뷰를 삭제하면 해당 ReviewHelpful 행만 CASCADE로 삭제한다.

`schema.sql`은 기존 테이블과 데이터를 삭제하지 않는다. 이미 있는 테이블은 IF NOT EXISTS로 건너뛰므로, 기존 테이블을 최신 구조로 변경하는 용도로는 사용할 수 없다.

## 데이터와 화면별 SQL

| 파일 | 내용 | 담당 |
| --- | --- | --- |
| data.sql | 가상 사용자·가게·메뉴·주문 데이터 입력 | DB 담당 |
| queries/home.sql | 주소·카테고리·가게 조회·검색·필터 | 홈 담당 |
| queries/my-page.sql | 사용자·리뷰·도움 수·즐겨찾기 조회 및 변경 | 마이이츠 담당 |
| queries/orders.sql | 주문 목록·상세·상태·금액·리뷰 여부 조회 | 주문내역 담당 |

빈 개발용 `db_team8`에서 `schema.sql` → `data.sql` 순서로 실행한다. 샘플은 고정 ID를 사용하므로 데이터 입력은 한 번만 실행한다. 이미 이전 샘플을 넣었다면 두 SQL 파일의 `db_team8`을 같은 새 테스트용 이름으로 맞춘 뒤 실행한다.

| 홈 검증 | 샘플 데이터 |
| --- | --- |
| 리뷰 있는 가게 / 없는 가게 | 1번 가게는 리뷰 2개·평균 4.5점이다. 3번은 완료 주문이 있지만 리뷰는 없다. |
| 영업 여부 | 1번 가게는 `IsOpen = 1`, 2번은 `IsOpen = 0`이다. |
| 복수 카테고리 | 1번 가게는 한식(1)과 치킨(2)에 모두 속한다. |
| 품절 메뉴 | 1번 가게의 메뉴 1번은 판매 가능, 2번은 품절이다. |
| 기본 주소 | 1번 사용자는 기본 주소가 있고, 2번은 일반 주소만 있고, 3번은 주소가 없다. |

샘플은 11개 테이블에 총 198행이다. 사용자 14명, 가게 14곳, 카테고리 14종, 메뉴 24개, 주문 24건, 리뷰 15건을 포함한다. 사용자 가입과 주소 등록은 2022~2026년, 즐겨찾기·주문·리뷰·리뷰 반응은 2024~2026년으로 나눴다. 주소와 우편번호는 성남시 수정구 도로명을 사용한 실습용 조합이다.

카테고리 14개 중 11개에는 배경이 투명한 PNG를 연결했다. 야식·디저트·국밥의 이미지 주소는 `NULL`이다. [카테고리 이미지](fixtures/categories)

가게·메뉴에는 GitHub에 저장한 음식 사진 16개를 사용한다. 메뉴 24개 중 19개에 사진이 있다. 카테고리·가게·메뉴 이미지 값이 `NULL`이면 API 응답에서 [기본 이미지](fixtures/common/no-photo.png)를 사용한다. [음식 사진 출처](fixtures/food/README.md)

API에서는 한 주문의 가게와 메뉴 가게 일치, 주문당 메뉴 최소 1개, 주문 합계 대비 할인 한도, 완료 주문의 리뷰 작성 여부를 별도로 확인한다.

## 검증

2026-11-15, 별도 MySQL 8.4.13 환경에서 생성·재실행·제약조건 등 51개 검증을 통과했다. [검증 기록](../docs/verification.md) · [검증 결과](../docs/schema-validation.json)

참고: [MySQL CHECK](https://dev.mysql.com/doc/refman/8.4/en/create-table-check-constraints.html), [함수 인덱스](https://dev.mysql.com/doc/refman/8.4/en/create-index.html#functional-key-parts).
