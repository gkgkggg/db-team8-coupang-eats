# Postman 로컬 baseUrl 설정

요청 주소는 `{{baseUrl}}/api/...` 형식이다. 각자 서버 주소·포트는 달라도 되지만 API 경로·메서드·입력값·응답 형식은 맞춘다.

## 환경 설정

1. Postman의 Import로 `DB8.postman_collection.json`과 `DB8-Local.postman_environment.json`을 가져온다.
2. Environments에서 `DB8 Local`을 열고 `baseUrl`의 로컬 값을 자신의 API 서버 주소로 수정한다.
3. 활성 환경으로 `DB8 Local`을 선택한다.
4. 요청을 열고 `{{baseUrl}}`에 마우스를 올려 실제 주소를 확인한 뒤 Send를 누른다.

| 항목 | 값 예시 |
| --- | --- |
| 활성 환경 | DB8 Local |
| 변수 이름 | baseUrl |
| 예시 값 | http://localhost:3000 |
| 자기 서버가 8080 포트일 때 | http://localhost:8080 |
| 요청 URL | {{baseUrl}}/api/home?userId={{userId}}&categoryId=2&keyword=치킨 |

`baseUrl`에는 프로토콜·호스트·API 서버 포트만 넣는다. 끝의 `/`와 `/api`는 넣지 않는다. 예를 들어 `http://localhost:8080`으로 설정하면 홈 요청은 `http://localhost:8080/api/home?...`으로 전송된다.

## 변수 우선순위와 팀 공유

- Collection에도 `baseUrl=http://localhost:3000` 예시가 있다. `DB8 Local` 환경을 선택하면 같은 이름의 환경 변수가 Collection 값보다 우선한다.
- 자기 주소·포트는 환경 변수의 로컬 값으로 관리한다. 팀원마다 같은 포트를 쓰도록 맞출 필요가 없다.
- `userId`, `storeId`, `orderId`는 Collection 변수에서 자기 샘플 데이터에 맞춰 변경한다.
- 여러 View를 하나의 서버에서 실행하면 한 baseUrl로 호출한다. 서버를 따로 실행하면 환경을 복제해 이름·baseUrl을 바꾸고 요청에 맞는 환경을 선택한다.
- 요청·검증 항목 변경은 Collection으로 Export해 공유한다. 개인 포트 변경만으로 공용 Collection을 수정하지 않는다.

## 실행 전 확인

`baseUrl`은 API 서버 주소다. MySQL 접속 포트와 구분한다. 예시의 3000은 확정된 포트가 아니며, 서버를 구현·실행한 뒤 요청을 보낸다.

공유 환경 파일에는 예시 주소만 들어 있다. 비밀번호·토큰·실제 개인정보가 포함된 환경 파일은 올리지 않는다.

공식 문서: [환경 변수 설정](https://learning.postman.com/docs/use/send-requests/variables/managing-environments), [변수 우선순위](https://learning.postman.com/docs/use/send-requests/variables/variables).
