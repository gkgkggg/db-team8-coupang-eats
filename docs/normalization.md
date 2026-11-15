# 주문–메뉴 예시의 1NF → 2NF → 3NF

## 1. 대상과 업무 규칙

주문–메뉴 테이블을 1NF부터 3NF까지 분해한다. 즐겨찾기·리뷰는 별도 관계로 추가한다. 서로 독립적인 1:N 목록을 한 번에 조인하면 행이 곱해지므로 구분해서 다룬다.

- 한 주문은 한 사용자·한 가게에 속한다.
- MenuID는 메뉴를 전역 식별하고 한 가게에만 속한다. 주문은 그 가게의 메뉴만 담는다.
- 옵션은 제외하며 한 주문의 같은 메뉴는 수량을 합친다. 키는 (OrderID, MenuID)다.
- UserName·UserPhone·StoreName·StorePhone·MenuName·CurrentPrice는 이 예시의 현재 마스터 정보다. 이름·전화번호·날짜는 키가 아니다.
- MenuNameAtOrder·UnitPriceAtOrder·DeliveryAddressText·Orders.DeliveryFee는 주문 당시 사실이다. 현재 값이 바뀌어도 유지한다.
- 함수 종속(Functional Dependency)은 데이터의 우연한 반복이 아닌 아래 업무 규칙으로 정의한다.

## 2. 정규화 전(UNF): 반복 그룹

학습용으로 주문 한 행에 메뉴 목록을 넣은 형태를 가정한다.

| OrderID | UserID | StoreID | 메뉴 반복 그룹(MenuID, 당시 메뉴명, 당시 단가, 수량) |
| --- | --- | --- | --- |
| 101 | 1 | 1 | (11, 후라이드(구명), 17000, 1); (12, 콜라, 2000, 2) |
| 102 | 2 | 1 | (11, 후라이드치킨, 18000, 2); (13, 감자튀김, 3000, 1) |
| 103 | 1 | 2 | (21, 치즈버거, 7000, 1); (22, 감자튀김, 2500, 2) |
| 104 | 1 | 1 | (11, 후라이드치킨, 18000, 1); (12, 콜라, 2000, 1) |

메뉴별 조회와 제약조건 적용을 위해 목록을 메뉴별 행으로 펼친다. 각 셀에는 원자값(Atomic Value) 하나를 저장한다.

## 3. 제1정규형(First Normal Form, 1NF): 한 행에 주문 메뉴 하나

전체 원본 컬럼:

```text
OrderID, OrderedAt, UserID, UserName, UserPhone, StoreID, StoreName, StorePhone, OrderStatus, DeliveryAddressText, DeliveryFee, DiscountAmount, MenuID, MenuName, CurrentPrice, MenuNameAtOrder, UnitPriceAtOrder, Quantity
```

[전체 18개 컬럼·8행 CSV](examples/order_1nf.csv)의 일부 컬럼을 아래에 표시했다. CSV는 정규화 설명용 가상 데이터다. DB에 적재할 샘플은 db/data.sql에 따로 작성한다.

| OrderID | UserID | StoreID | MenuID | MenuNameAtOrder | UnitPriceAtOrder | Quantity |
| --- | --- | --- | --- | --- | --- | --- |
| 101 | 1 | 1 | 11 | 후라이드(구명) | 17000 | 1 |
| 101 | 1 | 1 | 12 | 콜라 | 2000 | 2 |
| 102 | 2 | 1 | 11 | 후라이드치킨 | 18000 | 2 |
| 102 | 2 | 1 | 13 | 감자튀김 | 3000 | 1 |
| 103 | 1 | 2 | 21 | 치즈버거 | 7000 | 1 |
| 103 | 1 | 2 | 22 | 감자튀김 | 2500 | 2 |
| 104 | 1 | 1 | 11 | 후라이드치킨 | 18000 | 1 |
| 104 | 1 | 1 | 12 | 콜라 | 2000 | 1 |

각 셀은 메뉴별 값 하나이고 반복 목록이 없다. 그러나 주문·사용자·가게·현재 메뉴 정보가 여러 행에 반복된다.

### 함수 종속 집합

```text
OrderID → OrderedAt, UserID, StoreID, OrderStatus,
          DeliveryAddressText, DeliveryFee, DiscountAmount
UserID → UserName, UserPhone
StoreID → StoreName, StorePhone
MenuID → StoreID, MenuName, CurrentPrice
(OrderID, MenuID) → MenuNameAtOrder, UnitPriceAtOrder, Quantity
```

### 후보키(Candidate Key)·완전 함수 종속(Full Functional Dependency)

OrderID와 MenuID는 위 종속의 오른쪽에서 유도되지 않는다. 따라서 모든 후보키는 둘을 포함해야 한다. 두 속성의 폐포(Closure)는 전체 18개 속성을 포함하므로 유일한 후보키는 **(OrderID, MenuID)**다.

Quantity·UnitPriceAtOrder·MenuNameAtOrder는 이 업무 규칙에서 키 전체에 종속된다. OrderID만으로 메뉴별 수량·단가를 알 수 없고, MenuID만으로 과거 주문의 수량·당시 가격·당시 이름을 결정할 수 없다. 예를 들어 MenuID=11은 주문 101에서 17,000원, 주문 102·104에서는 18,000원이다.

### 이상 현상(Anomaly)

- 수정: 가게 전화번호 변경 시 여러 주문 메뉴 행을 수정해야 한다.
- 삽입: 주문이 없는 새 가게·메뉴를 이 원본만으로는 독립 저장하기 어렵다.
- 삭제: 마지막 주문 메뉴 행을 삭제하면 그 행에만 있던 마스터 정보도 함께 사라질 수 있다.

## 4. 제2정규형(Second Normal Form, 2NF): 부분 함수 종속 제거

| 키의 진부분집합 | 결정하는 속성 | 이동 위치 |
| --- | --- | --- |
| OrderID | 주문 시각·사용자·가게·상태·주소 스냅샷·적용 배달비·할인, 그리고 사용자의 현재 정보·가게 정보 | Orders_2NF |
| MenuID | 소속 가게·현재 메뉴명·현재 가격, 그리고 가게의 현재 정보 | Menus_2NF |
| OrderID + MenuID 전체 | 수량·주문 당시 단가·주문 당시 메뉴명 | OrderItems_2NF |

```text
Orders_2NF(
  OrderID PK, OrderedAt, UserID, UserName, UserPhone,
  StoreID, StoreName, StorePhone, OrderStatus,
  DeliveryAddressText, DeliveryFee, DiscountAmount
)
Menus_2NF(
  MenuID PK, StoreID, StoreName, StorePhone, MenuName, CurrentPrice
)
OrderItems_2NF(
  OrderID PK/FK, MenuID PK/FK,
  MenuNameAtOrder, UnitPriceAtOrder, Quantity
)
```

세 테이블 모두 해당 후보키의 일부에 비주요 속성이 종속되는 관계를 제거했으므로 제시된 업무 규칙에서 2NF다. 하지만 Orders_2NF의 UserID → UserName·UserPhone, StoreID → StoreName·StorePhone과 Menus_2NF의 StoreID → StoreName·StorePhone은 남아 있다.

## 5. 제3정규형(Third Normal Form, 3NF): 이행적 함수 종속 제거

```text
OrderID → UserID → UserName, UserPhone
OrderID → StoreID → StoreName, StorePhone
MenuID → StoreID → StoreName, StorePhone
```

사용자 현재 정보는 Users, 가게 현재 정보는 Stores로 분리한다. 주문·메뉴에는 연결에 필요한 키만 남긴다.

```text
Users(UserID PK, UserName, UserPhone)
Stores(StoreID PK, StoreName, StorePhone)
Menus(MenuID PK, StoreID FK, MenuName, CurrentPrice)
Orders(
  OrderID PK, OrderedAt, UserID FK, StoreID FK, OrderStatus,
  DeliveryAddressText, DeliveryFee, DiscountAmount
)
OrderItems(
  OrderID PK/FK, MenuID PK/FK,
  MenuNameAtOrder, UnitPriceAtOrder, Quantity
)
```

각 비키 속성은 해당 키 전체에 종속된다. 사용자·가게의 이름과 전화번호를 주문·메뉴 행에서 반복 저장하지 않는다. 일반적인 3NF 판단 조건은 모든 비자명한 종속 X→A에 대해 X가 슈퍼키(Superkey)이거나 A가 주요 속성(Prime Attribute)인 것이다. 이 예시의 마스터 테이블은 식별자가 결정자이고, 주문 항목의 비키 속성은 복합키 전체에 종속된다.

### 주문 스냅샷을 남기는 이유

- MenuID → CurrentPrice·MenuName은 현재 마스터 정보의 규칙이다.
- MenuID → UnitPriceAtOrder·MenuNameAtOrder는 과거 주문 전체에 성립하지 않는다.
- StoreID → Stores.DeliveryFee는 현재 기본 요금이고, StoreID → Orders.DeliveryFee는 가정하지 않는다.
- 주소·가격 스냅샷은 현재 마스터 값을 중복 캐시한 것이 아니라 시점이 다른 사실이다. 이 업무 규칙에서는 3NF를 위반하지 않는다.

## 6. 다른 기능의 테이블

위 원본에서 직접 분해한 것은 Users·Stores·Menus·Orders·OrderItems의 5개 관계다. 여기에 기능 요구사항으로 Addresses·Categories·StoreCategories·Favorites·Reviews·ReviewHelpful의 6개 관계를 추가한다.

- Users M:N Stores는 Favorites(UserID, StoreID)로 분해한다. CreatedAt은 해당 쌍에 종속된다.
- Stores M:N Categories는 StoreCategories(StoreID, CategoryID)로 분해한다. 비키 속성은 없다.
- Users M:N Reviews의 도움·비도움 반응은 ReviewHelpful(UserID, ReviewID)로 분해한다. IsHelpful과 CreatedAt은 이 복합키 전체에 종속되며, IsHelpful은 TRUE=도움이 돼요, FALSE=도움이 안 돼요다.
- Reviews.OrderID는 UNIQUE NOT NULL로 주문당 리뷰 0~1개를 나타낸다.
- 컬럼 사전의 CreatedAt·이미지·주소·판매 상태 등은 해당 기능에 필요한 속성으로 추가한다.

전체 타입·키·NULL·계산값·업무 제약은 [db-column-dictionary.md](db-column-dictionary.md)를 참고한다.

## 7. 무손실 조인(Lossless Join)

OrderItems가 실제 (OrderID, MenuID) 쌍을 유지한다. OrderID로 주문 헤더를, MenuID로 메뉴를, UserID·StoreID로 유일한 마스터를 결합하므로 해당 업무 규칙을 만족하는 원본 행을 복원할 수 있다. 핵심 함수 종속은 각 마스터·주문·주문 항목에 보존되고, 이행된 정보는 키 조인으로 유도한다.

```sql
SELECT o.OrderID, o.OrderedAt, o.UserID, u.UserName, u.UserPhone,
       o.StoreID, s.StoreName, s.StorePhone, o.OrderStatus,
       o.DeliveryAddressText, o.DeliveryFee, o.DiscountAmount,
       oi.MenuID, m.MenuName, m.CurrentPrice,
       oi.MenuNameAtOrder, oi.UnitPriceAtOrder, oi.Quantity
FROM OrderItems AS oi
JOIN Orders AS o ON o.OrderID = oi.OrderID
JOIN Users AS u ON u.UserID = o.UserID
JOIN Stores AS s ON s.StoreID = o.StoreID
JOIN Menus AS m ON m.MenuID = oi.MenuID
ORDER BY o.OrderID, oi.MenuID;
```

설명용 8행은 Python에서 투영·조인해 원본 18개 컬럼과 비교한다. MySQL에서 위 복원 질의를 실행한 결과는 샘플 데이터 적재 후 기록한다.
