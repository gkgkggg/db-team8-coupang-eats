# Postman 로컬 baseUrl 설정

8개 요청은 모두 `{{baseUrl}}/api/...` 형식입니다. 각자 로컬 API 서버의 주소·포트는 달라도 됩니다. API 경로·메서드·입력값·응답 규격을 공통으로 맞춥니다.

## 처음 한 번 설정

1. Postman의 Import로 `DB8.postman_collection.json`과 `DB8-Local.postman_environment.json`을 가져옵니다.
2. Environments에서 `DB8 Local`을 열고 `baseUrl`의 로컬 값을 자신의 API 서버 주소로 수정합니다.
3. 활성 환경으로 `DB8 Local`을 선택합니다.
4. 요청을 열고 `{{baseUrl}}`에 마우스를 올려 실제 주소를 확인한 뒤 Send합니다.

| 항목 | 값 예시 |
| --- | --- |
| 활성 환경 | DB8 Local |
| 변수 이름 | baseUrl |
| 기본 예시 값 | http://localhost:3000 |
| 자기 서버가 8080 포트일 때 | http://localhost:8080 |
| 요청 URL | {{baseUrl}}/api/home?userId={{userId}}&categoryId=2&keyword=치킨 |

`baseUrl`에는 프로토콜·호스트·API 서버 포트만 넣습니다. 끝의 `/`와 `/api`는 넣지 않습니다. 예를 들어 `http://localhost:8080`으로 설정하면 홈 요청은 `http://localhost:8080/api/home?...`으로 전송됩니다.

## 변수 우선순위와 팀 공유

- Collection에도 `baseUrl=http://localhost:3000` 예시가 있습니다. `DB8 Local` 환경을 선택하면 같은 이름의 환경 변수가 Collection 값보다 우선합니다.
- 자기 주소·포트는 환경 변수의 로컬 값으로 관리합니다. 팀원마다 같은 포트를 쓰도록 맞출 필요가 없습니다.
- `userId`, `storeId`, `orderId`는 Collection 변수에서 자기 샘플 데이터에 맞춰 변경합니다.
- 여러 View를 하나의 서버에서 실행하면 한 baseUrl로 호출합니다. 서버를 따로 실행하면 환경을 복제해 이름·baseUrl을 바꾸고 요청에 맞는 환경을 선택합니다.
- 요청·검증 항목 변경은 Collection으로 Export해 공유합니다. 개인 포트 변경만으로 공용 Collection을 수정하지 않습니다.

## 실행 전 확인

이 주소는 MySQL 접속 주소가 아니라 API 서버 주소입니다. 예시 3000은 확정된 서버 포트가 아닙니다. API 서버를 실제로 구현·실행해야 요청이 동작합니다.

공유 환경 파일에는 예시 주소만 들어 있습니다. 비밀번호·토큰·실제 개인정보가 포함된 환경 파일은 올리지 않습니다.

공식 문서: [환경 변수 설정](https://learning.postman.com/docs/use/send-requests/variables/managing-environments), [변수 우선순위](https://learning.postman.com/docs/use/send-requests/variables/variables).
