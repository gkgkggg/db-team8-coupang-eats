# 세 View 데이터베이스 컬럼 사전 — 3NF 설계안

작성 기준: 2026-11-07, 팀의 홈·마이이츠/즐겨찾기·주문내역 요구사항. 담당: 심영진(DB), 전지우(홈), 홍승민(마이이츠), 심동진(주문내역).

## 설계 범위·업무 규칙

- 대상 View는 홈 / 마이이츠(즐겨찾기 포함) / 주문내역 3개다. 아래 11개 테이블·57개 컬럼은 팀 검토용 설계안이다. 실제 서비스 내부 DB를 복제했다는 뜻은 아니다.
- 이름·전화번호·날짜·메뉴명·상호는 고유하다고 가정하지 않는다. 식별은 ID로 한다. Categories.CategoryName만 이 초안에서 별도 UNIQUE를 제안한다.
- 한 주문은 한 사용자·한 가게에 속한다. 한 메뉴는 한 가게에 속하며 MenuID를 다른 가게에 재배정하지 않는다.
- 메뉴 옵션·추가 구성은 제외한다. 한 주문에서 같은 MenuID는 한 항목으로 합산한다. 따라서 OrderItems의 복합 기본키는 (OrderID, MenuID)다. 서로 다른 옵션·단가의 같은 메뉴를 한 주문에 넣어야 하면 OrderLineNo와 옵션 테이블로 재설계한다.
- 한 주문의 리뷰는 최대 1개다. 즐겨찾기와 리뷰 도움 반응은 사용자·대상 쌍별로 최대 1개다.
- 현재 사용자·가게·메뉴 정보와 주문 당시의 메뉴명·단가·배송 주소·적용 배달비를 구분한다. 현재 값이 바뀌어도 주문 시점 값은 유지한다.
- 주문내역의 상호는 현재 Stores.StoreName을 표시한다. 과거 상호 보존이 필요하면 별도 StoreNameAtOrder를 검토한다.
- 금액은 원(KRW) 단위의 DECIMAL(10,0)으로 제안한다. 실제 결제 승인·취소·환불 처리와 쿠폰·광고·스탬프·로그인 구현은 이번 기본 설계 범위에서 제외한다.
- API 서버 언어·실행 포트는 미정이다. 팀원은 Postman의 로컬 baseUrl로 자기 서버 주소를 설정한다.

## 테이블 개요

| 테이블 | 용도 | 기본키(Primary Key) | 컬럼 수 |
| --- | --- | --- | --- |
| `Users` | 사용자 | UserID | 4 |
| `Addresses` | 사용자 주소 | AddressID | 8 |
| `Categories` | 음식 카테고리 | CategoryID | 4 |
| `Stores` | 가게 | StoreID | 9 |
| `StoreCategories` | 가게–카테고리 연결 | StoreID + CategoryID | 2 |
| `Menus` | 메뉴 | MenuID | 6 |
| `Favorites` | 즐겨찾기 | UserID + StoreID | 3 |
| `Orders` | 주문 기본 정보 | OrderID | 8 |
| `OrderItems` | 주문 항목 | OrderID + MenuID | 5 |
| `Reviews` | 주문 리뷰 | ReviewID | 5 |
| `ReviewHelpful` | 리뷰 도움 반응 | UserID + ReviewID | 3 |

## 컬럼 사전

NULL 허용 N=필수, Y=선택. FK는 외래키(Foreign Key), UNIQUE는 유일 제약이다. 자동 ID 생성·기본값·인덱스·삭제 정책은 실제 DDL 작성 시 확정한다.

### Users — 사용자

사용 View: 마이이츠 / 홈·주문 공통 식별. PK: (UserID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `UserID` | `BIGINT UNSIGNED` | PK | N | 사용자 식별자 |
| `UserName` | `VARCHAR(50)` | - | N | 현재 표시 이름; 고유하지 않음 |
| `UserPhone` | `VARCHAR(20)` | - | Y | 현재 전화번호; 화면에서 마스킹; 고유성 가정 없음 |
| `CreatedAt` | `DATETIME` | - | N | 가입·샘플 사용자 생성 시각 |

### Addresses — 사용자 주소

사용 View: 홈 선택 주소 / 마이이츠 주소 관리. PK: (AddressID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `AddressID` | `BIGINT UNSIGNED` | PK | N | 주소 식별자 |
| `UserID` | `BIGINT UNSIGNED` | FK → Users.UserID | N | 주소 소유 사용자 |
| `AddressLabel` | `VARCHAR(20)` | - | N | 집·회사 등 주소 별칭 |
| `PostalCode` | `CHAR(5)` | - | Y | 우편번호; 선행 0 보존 |
| `AddressLine1` | `VARCHAR(200)` | - | N | 도로명·건물 주소 |
| `AddressLine2` | `VARCHAR(100)` | - | Y | 상세 주소 |
| `IsDefault` | `BOOLEAN` | - | N | 기본 주소 여부; 기본값 FALSE |
| `CreatedAt` | `DATETIME` | - | N | 주소 등록 시각 |

### Categories — 음식 카테고리

사용 View: 홈 카테고리. PK: (CategoryID). 대체키: (CategoryName).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `CategoryID` | `INT UNSIGNED` | PK | N | 카테고리 식별자 |
| `CategoryName` | `VARCHAR(30)` | UNIQUE | N | 치킨·버거 등; 이 초안에서는 이름 중복 금지 |
| `CategoryImageURL` | `VARCHAR(500)` | - | Y | 카테고리 이미지 주소 |
| `DisplayOrder` | `INT UNSIGNED` | - | N | 표시 순서; 기본값 0; 동률 허용 |

### Stores — 가게

사용 View: 홈·즐겨찾기·주문내역. PK: (StoreID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `StoreID` | `BIGINT UNSIGNED` | PK | N | 가게 식별자 |
| `StoreName` | `VARCHAR(100)` | - | N | 현재 가게 이름; 중복 가능 |
| `StorePhone` | `VARCHAR(20)` | - | Y | 현재 가게 연락처; 중복 가능 |
| `StoreAddress` | `VARCHAR(255)` | - | N | 현재 가게 주소 |
| `StoreImageURL` | `VARCHAR(500)` | - | Y | 가게 대표 이미지 |
| `MinimumOrderAmount` | `DECIMAL(10,0)` | - | N | 현재 최소 주문 금액; 원(KRW); 0 이상 |
| `DeliveryFee` | `DECIMAL(10,0)` | - | N | 현재 기본 배달비; 원(KRW); 0 이상 |
| `EstimatedDeliveryMinutes` | `SMALLINT UNSIGNED` | - | Y | 가게가 제공하는 현재 기본 예상 시간(분) |
| `IsOpen` | `BOOLEAN` | - | N | 현재 주문 가능 여부; 기본값 TRUE |

### StoreCategories — 가게–카테고리 연결

사용 View: 홈 카테고리 필터. PK: (StoreID, CategoryID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `StoreID` | `BIGINT UNSIGNED` | PK(1)·FK → Stores.StoreID | N | 분류할 가게 |
| `CategoryID` | `INT UNSIGNED` | PK(2)·FK → Categories.CategoryID | N | 연결할 음식 카테고리 |

### Menus — 메뉴

사용 View: 홈 보조 데이터 / 주문내역 메뉴 연결. PK: (MenuID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `MenuID` | `BIGINT UNSIGNED` | PK | N | 메뉴 식별자; 가게 간 재사용·재배정하지 않음 |
| `StoreID` | `BIGINT UNSIGNED` | FK → Stores.StoreID | N | 메뉴를 판매하는 가게 |
| `MenuName` | `VARCHAR(100)` | - | N | 현재 메뉴명; 중복 가능 |
| `CurrentPrice` | `DECIMAL(10,0)` | - | N | 현재 판매 가격; 원(KRW); 0 이상 |
| `MenuImageURL` | `VARCHAR(500)` | - | Y | 메뉴 이미지 |
| `IsAvailable` | `BOOLEAN` | - | N | 현재 판매 가능 여부; 기본값 TRUE |

### Favorites — 즐겨찾기

사용 View: 마이이츠·즐겨찾기. PK: (UserID, StoreID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `UserID` | `BIGINT UNSIGNED` | PK(1)·FK → Users.UserID | N | 즐겨찾기한 사용자 |
| `StoreID` | `BIGINT UNSIGNED` | PK(2)·FK → Stores.StoreID | N | 즐겨찾기한 가게 |
| `CreatedAt` | `DATETIME` | - | N | 즐겨찾기 등록 시각 |

### Orders — 주문 기본 정보

사용 View: 주문내역 / 리뷰 사용자·가게 연결. PK: (OrderID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `OrderID` | `BIGINT UNSIGNED` | PK | N | 주문 식별자 |
| `UserID` | `BIGINT UNSIGNED` | FK → Users.UserID | N | 주문한 사용자 |
| `StoreID` | `BIGINT UNSIGNED` | FK → Stores.StoreID | N | 주문 대상 가게; 한 주문은 한 가게 |
| `OrderedAt` | `DATETIME` | - | N | 주문 시각 |
| `OrderStatus` | `VARCHAR(20)` | - | N | preparing / delivering / completed / cancelled |
| `DeliveryAddressText` | `VARCHAR(300)` | - | N | 주문 시점 배송 주소 스냅샷(Snapshot); 현재 주소와 독립 |
| `DeliveryFee` | `DECIMAL(10,0)` | - | N | 해당 주문에 실제 적용한 배달비; 원(KRW); 0 이상 |
| `DiscountAmount` | `DECIMAL(10,0)` | - | N | 해당 주문 할인액; 원(KRW); 0 이상; 기본값 0 |

### OrderItems — 주문 항목

사용 View: 주문내역 메뉴·수량·금액. PK: (OrderID, MenuID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `OrderID` | `BIGINT UNSIGNED` | PK(1)·FK → Orders.OrderID | N | 주문 |
| `MenuID` | `BIGINT UNSIGNED` | PK(2)·FK → Menus.MenuID | N | 주문 메뉴 |
| `Quantity` | `INT UNSIGNED` | - | N | 수량; 1 이상 |
| `UnitPriceAtOrder` | `DECIMAL(10,0)` | - | N | 주문 당시 단가; 원(KRW); 0 이상 |
| `MenuNameAtOrder` | `VARCHAR(100)` | - | N | 주문 당시 메뉴명 스냅샷 |

### Reviews — 주문 리뷰

사용 View: 마이이츠 내 리뷰 수 / 주문내역 리뷰 여부. PK: (ReviewID). 대체키: (OrderID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `ReviewID` | `BIGINT UNSIGNED` | PK | N | 리뷰 식별자 |
| `OrderID` | `BIGINT UNSIGNED` | UNIQUE·FK → Orders.OrderID | N | 대상 주문; 주문당 리뷰 최대 1개 |
| `Rating` | `TINYINT UNSIGNED` | - | N | 별점; 1~5 |
| `Content` | `TEXT` | - | Y | 리뷰 내용 |
| `CreatedAt` | `DATETIME` | - | N | 리뷰 작성 시각 |

### ReviewHelpful — 리뷰 도움 반응

사용 View: 마이이츠의 내 리뷰가 받은 도움 수. PK: (UserID, ReviewID).

| 컬럼 | MySQL 자료형 제안 | 키·참조 | NULL 허용 | 설명 |
| --- | --- | --- | --- | --- |
| `UserID` | `BIGINT UNSIGNED` | PK(1)·FK → Users.UserID | N | 도움 반응을 누른 사용자 |
| `ReviewID` | `BIGINT UNSIGNED` | PK(2)·FK → Reviews.ReviewID | N | 도움 반응 대상 리뷰 |
| `CreatedAt` | `DATETIME` | - | N | 도움 반응 시각 |

## 저장하지 않고 조회로 계산할 값

| 화면 표시값 | 계산 기준 |
| --- | --- |
| 내 리뷰 수 | Reviews를 Orders와 연결하고 Orders.UserID별 COUNT |
| 내 리뷰가 받은 도움 수 | ReviewHelpful → Reviews → Orders로 연결하여 리뷰 작성자(Orders.UserID)별 COUNT; 내가 누른 반응 수와 구분 |
| 즐겨찾기 수 | Favorites의 UserID별 COUNT |
| 가게 평균 별점·리뷰 수 | Reviews → Orders의 StoreID별 AVG(Rating), COUNT |
| 주문 메뉴 소계 | SUM(OrderItems.Quantity × OrderItems.UnitPriceAtOrder) |
| 주문 표시 금액 | 메뉴 소계 + Orders.DeliveryFee − Orders.DiscountAmount |
| 리뷰 작성 여부 | Reviews에 해당 OrderID가 존재하는지 확인 |

집계값을 Users·Stores·Orders에 중복 저장하지 않는다. 리뷰·즐겨찾기·도움 반응 같은 여러 1:N 목록을 직접 한 번에 조인하면 행이 곱해져 COUNT·SUM이 부풀 수 있으므로, 각각 먼저 집계하거나 별도 서브쿼리로 계산한다. 주문 표시 금액은 주문 데이터 기준이며 실제 결제 승인 여부를 뜻하지 않는다.

## View·API와 컬럼 연결

| View/API | 주요 테이블·컬럼 |
| --- | --- |
| 홈 GET /api/home | Addresses.UserID·IsDefault·AddressLine1·AddressLine2, Categories.*, StoreCategories.*, Stores.* |
| 마이이츠 GET /api/users/{userId}/summary | Users.UserName·UserPhone, Orders.UserID, Reviews.OrderID, ReviewHelpful.ReviewID, Favorites.UserID |
| 즐겨찾기 GET/POST/DELETE | Favorites(UserID,StoreID), Favorites.CreatedAt, Stores의 가게 정보 |
| 주문 목록 GET /api/users/{userId}/orders | Orders.UserID·OrderStatus·OrderedAt·DeliveryFee·DiscountAmount, Stores.StoreName·StoreImageURL |
| 주문 상세 GET /api/orders/{orderId} | OrderItems의 메뉴명 스냅샷·수량·단가, Menus.MenuImageURL, Reviews.OrderID |

## 관계·무결성(Integrity)

- Users 1:N Addresses / Orders / Favorites / ReviewHelpful.
- Stores 1:N Menus / Orders / Favorites / StoreCategories.
- Categories 1:N StoreCategories.
- Orders 1:N OrderItems, Orders 1:0..1 Reviews, Menus 1:N OrderItems.
- Reviews 1:N ReviewHelpful.
- Users M:N Stores → Favorites. Stores M:N Categories → StoreCategories. Orders M:N Menus → OrderItems. Users M:N Reviews(도움 반응) → ReviewHelpful.
- PK·FK 컬럼의 자료형과 UNSIGNED 여부를 맞춘다. FK는 PK 또는 명시적 UNIQUE NOT NULL 키를 참조하도록 한다.
- Quantity ≥ 1, Rating 1~5, 금액 ≥ 0, OrderStatus 허용값을 검사한다. 실제 MySQL 버전을 확인한 후 지원되는 CHECK와 API 검증으로 구현한다.
- 한 주문의 모든 메뉴는 Orders.StoreID와 같은 가게여야 한다. 단순 FK 두 개만으로 이 교차 테이블 규칙이 자동 보장되지는 않는다. 주문 작성 API의 트랜잭션에서 검사한다.
- 주문 할인액이 소계+배달비를 넘지 않는지 주문 항목과 함께 트랜잭션에서 검사한다. 타 테이블 집계를 CHECK에 넣지 않는다.
- 기본 주소는 사용자별 최대 1개를 허용한다. 여러 일반 주소를 막는 UNIQUE(UserID, IsDefault)는 사용하지 않는다. 주소 변경 트랜잭션과 필요한 별도 제약 설계를 검토한다.
- 리뷰 작성자는 Reviews.OrderID → Orders.UserID로 확인한다. 주문 가게는 Orders.StoreID에서 가져와 Reviews에 중복 저장하지 않는다.
- 주문·주문 항목·리뷰는 이력 보존을 위해 참조 중인 사용자·가게·메뉴를 임의 삭제하지 않는다. 메뉴는 IsAvailable, 가게는 IsOpen 등 운영 값으로 관리하고 실제 삭제 정책은 DDL 작성 전에 합의한다.

## 정규형 확인

업무 규칙을 함수 종속(Functional Dependency)으로 정의하면 각 기본 엔터티의 비키 속성은 식별자 전체에 종속된다. 연결 테이블은 복합키 전체에 종속되거나 비키 속성이 없다. Categories의 CategoryName, Reviews의 OrderID는 UNIQUE NOT NULL 대체 후보키이므로 이 키로 결정되는 속성도 3NF 조건에 맞는다.

단순히 ID를 추가해서 3NF라고 주장하는 것이 아니라, 이름·가게 정보·현재 메뉴 정보를 소유 엔터티에 두고 부분·이행 종속을 제거한다. 아래 업무 규칙 외에 추가 종속이 발견되면 재검토한다.

주문 당시 스냅샷은 현재 값과 다른 사실이다. MenuID → UnitPriceAtOrder·MenuNameAtOrder, StoreID → Orders.DeliveryFee, 현재 AddressID → 모든 주문의 DeliveryAddressText라는 종속은 가정하지 않는다.

정규화 예시·함수 종속·분해 과정은 [normalization.md](normalization.md)에 있다. 이 설계안은 아직 db/schema.sql에 적용한 DDL이나 MySQL 실행 결과가 아니다.

## 참고

- [MySQL 외래키](https://dev.mysql.com/doc/refman/8.4/en/create-table-foreign-keys.html)
- [MySQL CHECK 제약](https://dev.mysql.com/doc/refman/8.4/en/create-table-check-constraints.html)
