// 홈 API 자동 검증. 빈 db_team8에 schema.sql → test/home-seed.sql을 넣은 상태에서 실행한다.
const test = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const pool = require('../src/db');

let server;
let base;

test.before(async () => {
  server = app.listen(0);
  await new Promise((r) => server.once('listening', r));
  base = `http://127.0.0.1:${server.address().port}/api`;
});

test.after(async () => {
  server.close();
  await pool.end();
});

const get = async (path) => {
  const res = await fetch(base + path);
  return { status: res.status, body: await res.json() };
};
const ids = (list) => list.map((s) => s.storeId);
const defaultImageUrl = 'https://raw.githubusercontent.com/gkgkggg/db-team8-coupang-eats/main/db/fixtures/common/no-photo.png';

test('카테고리 목록: 표시 순서', async () => {
  const { status, body } = await get('/categories');
  assert.equal(status, 200);
  assert.deepEqual(body.map((c) => c.categoryName), ['한식', '치킨', '피자', '분식', '디저트']);
  assert.deepEqual(Object.keys(body[0]), ['categoryId', 'categoryName', 'categoryImageUrl', 'displayOrder']);
  assert.equal(body[0].categoryImageUrl, 'https://example.com/img/cat-korean.png');
  assert.equal(body.find((category) => category.categoryId === 5).categoryImageUrl, defaultImageUrl);
});

test('가게 목록: 전체·이름순·별점 집계', async () => {
  const { status, body } = await get('/stores');
  assert.equal(status, 200);
  assert.equal(body.length, 6);
  const s1 = body.find((s) => s.storeId === 1);
  assert.equal(s1.rating, 4.5);
  assert.equal(s1.reviewCount, 2);
  assert.equal(s1.isOpen, true);
  assert.equal(s1.deliveryFee, 3000);
  assert.equal(s1.storeImageUrl, 'https://example.com/img/s1.png');
  const s6 = body.find((s) => s.storeId === 6);
  assert.equal(s6.storeImageUrl, defaultImageUrl);
  assert.equal(s6.rating, null);
  assert.equal(s6.reviewCount, 0);
  const names = body.map((s) => s.storeName);
  assert.deepEqual(names, [...names].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0)));
});

test('가게 목록: 카테고리 필터 (여러 카테고리 가게 중복 없음)', async () => {
  const chicken = await get('/stores?categoryId=2');
  assert.deepEqual(ids(chicken.body).sort(), [1, 2, 5]);
  const pizza = await get('/stores?categoryId=3');
  assert.deepEqual(ids(pizza.body).sort(), [3, 5]);
  const empty = await get('/stores?categoryId=5');
  assert.equal(empty.status, 200);
  assert.deepEqual(empty.body, []);
});

test('가게 목록: 검색·검색+카테고리·결과 없음', async () => {
  assert.deepEqual(ids((await get('/stores?keyword=' + encodeURIComponent('치킨'))).body).sort(), [1, 2, 5]);
  assert.deepEqual(ids((await get(`/stores?categoryId=3&keyword=${encodeURIComponent('치킨')}`)).body), [5]);
  const none = await get('/stores?keyword=' + encodeURIComponent('없는가게'));
  assert.equal(none.status, 200);
  assert.deepEqual(none.body, []);
  assert.equal((await get('/stores?keyword=%20%20')).body.length, 6);
});

test('가게 목록: %·_ 는 문자 그대로 검색', async () => {
  assert.deepEqual(ids((await get('/stores?keyword=' + encodeURIComponent('%'))).body), [6]);
  assert.deepEqual(ids((await get('/stores?keyword=' + encodeURIComponent('_'))).body), [6]);
});

test('가게 목록: 정렬', async () => {
  assert.deepEqual(ids((await get('/stores?sort=deliveryFee')).body), [2, 6, 4, 3, 5, 1]);
  assert.deepEqual(ids((await get('/stores?sort=rating')).body), [3, 1, 2, 4, 5, 6]);
});

test('가게 목록: 잘못된 입력 400, 없는 카테고리 404', async () => {
  for (const q of ['categoryId=abc', 'categoryId=0', 'categoryId=-1', 'categoryId=1.5', 'sort=price',
    'categoryId=1&categoryId=2', 'keyword=' + 'a'.repeat(101)]) {
    const { status, body } = await get('/stores?' + q);
    assert.equal(status, 400, q);
    assert.equal(body.error.code, 'BAD_REQUEST');
  }
  const { status, body } = await get('/stores?categoryId=999');
  assert.equal(status, 404);
  assert.equal(body.error.code, 'NOT_FOUND');
});

test('가게 상세: 정상·리뷰 없음·404·400', async () => {
  const { status, body } = await get('/stores/3');
  assert.equal(status, 200);
  assert.equal(body.storeName, '도우피자');
  assert.equal(body.storeAddress, '경기 성남시 수정구 성남대로 3');
  assert.equal(body.minimumOrderAmount, 20000);
  assert.equal(body.rating, 5);
  assert.equal(body.reviewCount, 2);
  const closed = await get('/stores/4');
  assert.equal(closed.body.isOpen, false);
  assert.equal(closed.body.rating, null);
  assert.equal(closed.body.storePhone, null);
  assert.equal(closed.body.storeImageUrl, defaultImageUrl);
  assert.equal((await get('/stores/999')).status, 404);
  assert.equal((await get('/stores/abc')).status, 400);
});

test('가게 메뉴: 정상·판매 중지·빈 목록·404·400', async () => {
  const { status, body } = await get('/stores/1/menus');
  assert.equal(status, 200);
  assert.deepEqual(body.map((m) => m.menuName), ['후라이드치킨', '양념치킨', '치즈볼']);
  assert.equal(body[0].currentPrice, 19000);
  assert.equal(body[0].menuImageUrl, 'https://example.com/img/m1.png');
  assert.equal(body[1].menuImageUrl, defaultImageUrl);
  assert.equal(body[2].isAvailable, false);
  const empty = await get('/stores/6/menus');
  assert.equal(empty.status, 200);
  assert.deepEqual(empty.body, []);
  assert.equal((await get('/stores/999/menus')).status, 404);
  assert.equal((await get('/stores/0/menus')).status, 400);
});

test('홈: 선택 주소·카테고리·가게 목록 한 번에', async () => {
  const { status, body } = await get('/home?userId=1');
  assert.equal(status, 200);
  assert.deepEqual(Object.keys(body), ['address', 'categories', 'stores']);
  assert.equal(body.address.addressLabel, '기숙사');
  assert.equal(body.address.addressLine2, '제1기숙사 101호');
  assert.equal(body.categories.length, 5);
  assert.equal(body.stores.length, 6);
});

test('홈: 카테고리·검색·정렬 반영', async () => {
  const { status, body } = await get(`/home?userId=1&categoryId=2&keyword=${encodeURIComponent('치킨')}&sort=rating`);
  assert.equal(status, 200);
  assert.deepEqual(ids(body.stores), [1, 2, 5]);
  assert.equal(body.categories.length, 5);
  const none = await get('/home?userId=1&keyword=' + encodeURIComponent('없는가게'));
  assert.deepEqual(none.body.stores, []);
});

test('홈: 기본 주소 없는 사용자는 address null', async () => {
  const { status, body } = await get('/home?userId=2');
  assert.equal(status, 200);
  assert.equal(body.address, null);
});

test('홈: userId 누락·잘못된 입력 400, 없는 사용자·카테고리 404', async () => {
  for (const q of ['', 'userId=', 'userId=abc', 'userId=1&userId=2', 'userId=1&sort=price', 'userId=1&categoryId=x']) {
    const { status, body } = await get('/home?' + q);
    assert.equal(status, 400, q);
    assert.equal(body.error.code, 'BAD_REQUEST');
  }
  assert.equal((await get('/home?userId=999')).status, 404);
  assert.equal((await get('/home?userId=1&categoryId=999')).status, 404);
});

test('없는 경로 404', async () => {
  const { status, body } = await get('/nope');
  assert.equal(status, 404);
  assert.equal(body.error.code, 'NOT_FOUND');
});
