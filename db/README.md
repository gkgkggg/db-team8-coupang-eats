# MySQL 작업

담당: 심영진. 현재 SQL 파일은 작업 위치를 정한 빈 초안입니다.

- schema.sql: CREATE TABLE, PK/FK, UNIQUE, 생성 순서
- data.sql: 가상 사용자·가게·주문·즐겨찾기 데이터
- queries/home.sql: 전지우
- queries/my-page.sql: 홍승민
- queries/orders.sql: 심동진

구현 후 새 MySQL DB에서 schema.sql → data.sql 순서로 실행하고 View별 SQL을 검증합니다.
MySQL 버전, DB 생성 명령, 실행 방법은 확정 후 이 파일에 기록합니다.

Users–Stores의 M:N은 Favorites로, Orders–Menus의 M:N은 OrderItems로 연결합니다.
Favorites의 사용자·가게 중복과 리뷰 도움 반응의 사용자·리뷰 중복을 제한합니다.
