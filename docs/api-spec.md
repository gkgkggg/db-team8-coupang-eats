# API 명세

2026-11-15 기준 설계다. API 구현 전이며 서버 언어와 공통 JSON 형식은 팀에서 정한다. 아래 목록에서 구현할 기능을 선택하고, 로컬 서버 주소는 Postman 환경 변수 `baseUrl`로 설정한다.

### 기본 API

| View | 담당 | 메서드·경로 | 입력 | 기능·응답 |
| --- | --- | --- | --- | --- |
| 홈 | 홈 담당 | `GET /api/home` | userId, categoryId·keyword 선택 | 선택 주소·카테고리·가게 목록 |
| 마이이츠 | 마이이츠 담당 | `GET /api/users/{userId}/summary` | 경로의 userId | 이름·마스킹 전화번호·내 리뷰 수·받은 도움 수·즐겨찾기 수 |
| 마이이츠 | 마이이츠 담당 | `GET /api/users/{userId}/favorites` | 경로의 userId | 즐겨찾기 가게 목록·가게 정보 |
| 마이이츠 | 마이이츠 담당 | `POST /api/users/{userId}/favorites` | {"storeId":3} | 즐겨찾기 추가 |
| 마이이츠 | 마이이츠 담당 | `DELETE /api/users/{userId}/favorites/{storeId}` | 경로의 userId, storeId | 즐겨찾기 해제 |
| 주문내역 | 주문내역 담당 | `GET /api/users/{userId}/orders` | status 선택 | 주문 목록·가게·메뉴 요약·금액·리뷰 여부 |
| 주문내역 | 주문내역 담당 | `GET /api/orders/{orderId}` | 경로의 orderId | 주문 정보·항목별 수량/단가·배송 주소·합계·리뷰 여부 |

과거 주문과 준비 중 주문은 같은 주문 목록 API에 status만 달리 전달한다.

- 홈: `GET /api/home?userId=1&categoryId=2&keyword=치킨`
- 과거 주문: `GET /api/users/1/orders?status=completed`
- 준비 중 주문: `GET /api/users/1/orders?status=preparing`
- 배달 중·취소도 각각 `status=delivering`, `status=cancelled`로 조회한다. status를 생략하면 해당 사용자의 전체 주문을 최신순으로 조회한다.
- 주문 금액은 `SUM(Quantity × UnitPriceAtOrder) + DeliveryFee − DiscountAmount`로 계산한다.

### 홈

담당: 홈 담당. `/api/home`에서 한 번에 받거나 아래 API를 나눠 호출한다. 가게 상세·메뉴는 홈의 펼침 영역이나 팝업에 표시할 수 있다.

| 메서드·경로 | 입력 | 기능·응답 | 사용 테이블 |
| --- | --- | --- | --- |
| `GET /api/categories` | 없음 | 카테고리 ID·이름·이미지·표시 순서 | Categories |
| `GET /api/stores` | categoryId, keyword, sort 선택 | 검색·분류·정렬한 가게 목록 | Stores, StoreCategories, Orders, Reviews |
| `GET /api/stores/{storeId}` | 경로의 storeId | 가게 이름·주소·배달비·최소 주문 금액·영업 여부·별점 | Stores, Orders, Reviews |
| `GET /api/stores/{storeId}/menus` | 경로의 storeId | 메뉴명·현재 가격·이미지·판매 가능 여부 | Menus |

정렬안: 이름순(name), 배달비순(deliveryFee), 별점순(rating). 별점과 리뷰 수는 Reviews와 Orders를 먼저 집계해 가게 목록에 연결한다. 위치·거리 기반 검색은 구현 범위에서 제외한다.

### 마이이츠·주소·리뷰

담당: 마이이츠 담당. 사용자 정보는 summary에 포함하거나 별도로 조회한다. 주소 조회는 홈에서도 사용한다. 주소 변경 담당은 마이이츠 담당으로 제안한다.

| 메서드·경로 | 입력 | 기능·응답 | 사용 테이블 |
| --- | --- | --- | --- |
| `GET /api/users/{userId}` | 경로의 userId | 사용자 이름·마스킹 전화번호 | Users |
| `GET /api/users/{userId}/addresses` | 경로의 userId | 주소 목록·별칭·기본 주소 여부 | Addresses |
| `POST /api/users/{userId}/addresses` | 주소 별칭·우편번호·기본/상세 주소 | 주소 등록 | Addresses |
| `PUT /api/users/{userId}/addresses/{addressId}` | 수정할 주소 전체 필드 | 주소 수정 | Addresses |
| `DELETE /api/users/{userId}/addresses/{addressId}` | 경로의 userId, addressId | 주소 삭제 | Addresses |
| `PUT /api/users/{userId}/default-address` | {"addressId":10} | 기본 주소 변경 | Addresses |
| `GET /api/users/{userId}/reviews` | 경로의 userId | 내 리뷰 목록·가게·별점·내용·받은 도움 수 | Reviews, Orders, Stores, ReviewHelpful |
| `PUT /api/users/{userId}/helpful-reviews/{reviewId}` | 경로의 userId, reviewId와 JSON의 isHelpful(true/false) | 도움·비도움 반응 등록 또는 변경 | ReviewHelpful |
| `DELETE /api/users/{userId}/helpful-reviews/{reviewId}` | 경로의 userId, reviewId | 도움·비도움 반응 취소 | ReviewHelpful |

- 주소 등록·수정 입력: addressLabel, postalCode, addressLine1, addressLine2. 기본 주소는 별도 변경 API로 지정한다.
- 기본 주소 변경은 사용자 소유 주소인지 확인하고 기존 기본값 해제와 새 주소 지정을 한 트랜잭션(Transaction)에서 처리한다. 기본 주소 삭제 후에는 기본 주소가 없을 수 있으며, 다음 조회에서 다시 선택하도록 한다.
- 주소를 수정·삭제해도 Orders.DeliveryAddressText에 저장된 과거 배송 주소는 바꾸지 않는다.
- 반응 입력은 `{"isHelpful":true}` 또는 `{"isHelpful":false}`다. isHelpful은 필수 Boolean이며 누락·null·문자열은 400으로 처리한다. 같은 사용자·리뷰의 반응이 있으면 IsHelpful만 바꾸고 CreatedAt은 유지한다. 같은 값을 재요청하면 그대로 유지한다.
- 반응 취소는 DELETE로 행을 삭제한다. 행이 없는 상태는 미참여이며 FALSE는 '도움이 안 돼요'다.
- summary의 helpfulCount는 내 리뷰가 받은 IsHelpful=TRUE만 집계한다. 리뷰별 helpfulCount와 notHelpfulCount는 TRUE와 FALSE를 각각 세고, myReaction은 현재 사용자의 true/false 또는 미참여 null로 반환하도록 제안한다. 등록·변경·취소 후 조회에 반영한다.

### 주문내역·리뷰 작성

담당: 주문내역 담당. 리뷰 내용을 보여주거나 작성 버튼을 동작시킬 때 추가한다. 리뷰 목록은 마이이츠에서도 같은 데이터를 사용한다.

| 메서드·경로 | 입력 | 기능·응답 | 사용 테이블 |
| --- | --- | --- | --- |
| `GET /api/orders/{orderId}/review` | 경로의 orderId | 해당 주문의 리뷰·별점·내용 | Reviews |
| `POST /api/orders/{orderId}/review` | {"rating":5,"content":"맛있어요"} | 완료 주문의 리뷰 작성 | Reviews, Orders |
| `PUT /api/reviews/{reviewId}` | {"rating":4,"content":"수정 내용"} | 리뷰 별점·내용 수정 | Reviews |
| `DELETE /api/reviews/{reviewId}` | 경로의 reviewId | 리뷰 삭제 | Reviews, ReviewHelpful |

리뷰 작성 규칙안: 완료 주문당 최대 1개, 별점 1~5. 리뷰 삭제 시 연결된 ReviewHelpful도 함께 처리한다. 재주문·실제 주문 생성·결제·쿠폰은 이번 API 목록에서 제외한다.

### 공통 처리

- 이 프로젝트에서 구현할 로컬 API 경로다.
- `{userId}`, `{storeId}`, `{orderId}` 등의 경로 변수는 샘플 ID로 바꾼다. Postman 주소 앞에는 `{{baseUrl}}`을 붙인다.
- 로컬 시연은 샘플 사용자 1명으로 시작한다. 여러 사용자를 사용하면 주소·주문·리뷰 수정 시 소유자를 확인하는 방식을 정한다.
- 목록 조회 결과가 없으면 빈 배열을 반환한다. 없는 ID는 404, 잘못된 입력은 400, 중복 즐겨찾기·중복 리뷰는 409로 처리하는 안이다. 반응 등록·변경은 (UserID, ReviewID)당 한 행을 유지한다.
- 응답 필드는 세 화면 담당이 정한다. 사용 테이블은 DB 컬럼 사전을 따른다.
- Postman Collection에는 요청 예시 8개가 있다. 구현한 API에 맞춰 요청과 검증 항목을 추가한다.

## Postman

[로컬 설정 안내](../postman/README.md) · [Collection](../postman/DB8.postman_collection.json) · [환경 파일](../postman/DB8-Local.postman_environment.json)

## 확인할 항목

- 홈: 전체·검색·카테고리·검색 결과 없음.
- 마이이츠: 집계 정확성, 즐겨찾기 0건·추가·해제·중복.
- 주문내역: 상태·금액·리뷰 여부·주문 여러 건·0건.
- 선택 구현: 주소 소유자·기본 주소 전환, 리뷰 중복·별점 범위, 도움/비도움 등록·전환·취소·집계·중복.
- MySQL 조회·변경 결과와 JSON을 비교한다.
