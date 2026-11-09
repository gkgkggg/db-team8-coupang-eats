# API 설계 초안

서버 언어·응답 형식은 미정입니다. 아래 경로는 합의 전 설계 예시입니다.
로컬 호스트·포트는 각자 설정하고, Postman의 활성 환경 변수 `baseUrl`로 전달합니다. 예: `http://localhost:3000` 또는 `http://localhost:8080`. 팀 공통 API 경로·메서드·입력값·응답 규격을 맞춥니다.
userId를 경로·파라미터로 전달하는 것은 로컬 샘플 테스트 예시이며 인증 방식은 별도 결정합니다.

| View | 담당자 | 메서드 | 경로 | 목적 |
| --- | --- | --- | --- | --- |
| 홈 | 홈 담당 | GET | /api/home?userId=1&categoryId=2&keyword=치킨 | 주소·카테고리·가게 목록 |
| 마이이츠 | 마이이츠 담당 | GET | /api/users/1/summary | 사용자·리뷰·도움·즐겨찾기 수 |
| 마이이츠 | 마이이츠 담당 | GET | /api/users/1/favorites | 즐겨찾기 목록 |
| 마이이츠 | 마이이츠 담당 | POST | /api/users/1/favorites | 즐겨찾기 추가 |
| 마이이츠 | 마이이츠 담당 | DELETE | /api/users/1/favorites/3 | 즐겨찾기 해제 |
| 주문내역 | 주문내역 담당 | GET | /api/users/1/orders?status=completed | 과거 주문 |
| 주문내역 | 주문내역 담당 | GET | /api/users/1/orders?status=preparing | 준비 중 주문 |
| 주문내역 | 주문내역 담당 | GET | /api/orders/101 | 주문 상세 |

즐겨찾기 추가 JSON: `{"storeId": 3}`

## 합의할 사항
- 서버 언어·프레임워크, MySQL 버전, 공통 JSON 필드·자료형
- HTTP 상태 코드와 입력 오류·데이터 없음 처리
- 사용자 식별, 주문 금액 정의, 리뷰 도움 수의 집계 기준
- 선택 기능: 재주문·리뷰 등록·쿠폰·스탬프·시연용 웹

## 검증
- 홈: 전체·검색·카테고리·결과 없음·잘못된 입력
- 마이이츠: 집계 정확성, 즐겨찾기 0건·추가·해제·중복
- 주문내역: 상태·금액·리뷰 여부·여러 건·0건
- 모든 응답은 실제 MySQL 결과와 비교
