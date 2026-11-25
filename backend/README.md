# API 서버

홈·마이이츠·주문내역 담당이 같은 서버 프로젝트에서 API를 구현한다. 홈 API를 Node.js(Express) + mysql2로 먼저 구현했다. 팀에서 다른 언어로 정하면 SQL(`db/queries/home.sql`)과 응답 형식은 그대로 옮긴다.

[API 명세](../docs/api-spec.md)

## 실행

Node.js 18 이상, MySQL 8.0.16 이상.

1. `db/schema.sql` 실행 → 샘플 데이터 입력 (`db/data.sql`, 작성 전이면 `backend/test/home-seed.sql`)
2. 저장소 루트에서 `.env.example`을 `.env`로 복사하고 `DB_USER`, `DB_PASSWORD`를 자기 MySQL 계정으로 바꾼다.
3. 서버 실행

```bash
cd backend
npm install
npm start          # http://localhost:3000 (SERVER_PORT로 변경)
```

## 구조

```
backend/
  src/server.js        서버 시작
  src/app.js           라우터 연결, 404·오류 처리
  src/db.js            MySQL 연결 풀 (.env 사용)
  src/errors.js        400·404·500 JSON 오류
  src/routes/home.js   홈 API
  test/home-seed.sql   홈 테스트용 가상 데이터
  test/home.test.js    홈 API 자동 검증 (npm run test:home)
```

마이이츠·주문내역 API는 `src/routes/`에 파일을 추가하고 `src/app.js`에서 `app.use('/api', ...)`로 연결한다.

## 공통 응답 형식 (제안)

- 성공: 목록은 JSON 배열, 단건은 JSON 객체. 필드명은 camelCase.
- 오류: `{"error": {"code": "BAD_REQUEST" | "NOT_FOUND" | "INTERNAL_ERROR", "message": "..."}}`
- 금액·별점은 숫자, 영업·판매 여부는 true/false, 값이 없으면 null.

## 홈 API

| 메서드·경로 | 입력 | 응답 | 오류 |
| --- | --- | --- | --- |
| `GET /api/home` | `userId` 필수, `categoryId`·`keyword`·`sort` 선택 (가게 목록과 같음) | `{address, categories, stores}` — address는 기본 주소 `{addressId, addressLabel, postalCode, addressLine1, addressLine2}`, 없으면 null | userId 누락·잘못된 입력 400 / 없는 사용자·카테고리 404 |
| `GET /api/categories` | 없음 | `[{categoryId, categoryName, categoryImageUrl, displayOrder}]` 표시 순서 | - |
| `GET /api/stores` | `categoryId`, `keyword`, `sort`(name·deliveryFee·rating, 기본 name) 선택 | `[{storeId, storeName, storeImageUrl, deliveryFee, minimumOrderAmount, estimatedDeliveryMinutes, isOpen, rating, reviewCount}]` | 잘못된 categoryId·sort, 100자 초과 keyword 400 / 없는 categoryId 404 |
| `GET /api/stores/{storeId}` | 경로의 storeId | 가게 목록 필드 + `storePhone`, `storeAddress` | 잘못된 ID 400 / 없는 가게 404 |
| `GET /api/stores/{storeId}/menus` | 경로의 storeId | `[{menuId, menuName, currentPrice, menuImageUrl, isAvailable}]` 판매 중지 메뉴 포함 | 잘못된 ID 400 / 없는 가게 404 |

- 별점(rating)은 가게별 평균을 소수 첫째 자리로 반올림한다. 리뷰가 없으면 `rating: null`, `reviewCount: 0`.
- 별점순은 별점 높은 순 → 리뷰 수 많은 순이며, 리뷰 없는 가게는 뒤에 둔다.
- keyword는 가게 이름 부분 일치 검색이다. 앞뒤 공백은 제거하고, 빈 값이면 전체를 조회한다. `%`, `_`는 문자 그대로 검색한다.
- 조건에 맞는 가게·메뉴가 없으면 빈 배열(200)을 반환한다.
