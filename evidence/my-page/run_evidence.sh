#!/bin/bash
# 마이이츠·즐겨찾기 API 증빙 자동 실행 (팀 db/data.sql 기준)
# 사용: 서버(python app.py)를 켠 뒤  bash evidence/my-page/run_evidence.sh
BASE="${BASE:-http://localhost:5001}"
OUT="$(cd "$(dirname "$0")" && pwd)/api-results.txt"
PASS=0
FAIL=0
LAST=""
: > "$OUT"

pretty() {
  if [ -z "$1" ]; then echo "(본문 없음)"; return; fi
  echo "$1" | python3 -c 'import sys,json
raw=sys.stdin.read()
try:
    print(json.dumps(json.loads(raw), ensure_ascii=False, indent=2))
except Exception:
    print(raw)'
}

# call <기대 상태코드> <설명> <메서드> <경로> [JSON body]
call() {
  local expect="$1" label="$2" method="$3" path="$4" body="$5"
  local resp code result
  if [ -n "$body" ]; then
    resp=$(curl -s -w $'\n%{http_code}' -X "$method" "$BASE$path" -H 'Content-Type: application/json' -d "$body")
  else
    resp=$(curl -s -w $'\n%{http_code}' -X "$method" "$BASE$path")
  fi
  code="${resp##*$'\n'}"
  LAST="${resp%$'\n'*}"
  if [ "$code" = "$expect" ]; then result="PASS"; PASS=$((PASS+1)); else result="FAIL"; FAIL=$((FAIL+1)); fi
  {
    echo "### $label"
    echo "$method $path"
    if [ -n "$body" ]; then echo "body: $body"; fi
    echo "status: $code (expected $expect) -> $result"
    pretty "$LAST"
    echo
  } | tee -a "$OUT"
}

jget() { echo "$LAST" | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["'"$1"'"])'; }

code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/users/1")
if [ "$code" != "200" ]; then
  echo "서버 응답 이상($code). python app.py 실행 여부와 DB 상태를 확인하세요."
  exit 1
fi

echo "===== 즐겨찾기 =====" | tee -a "$OUT"
call 200 "즐겨찾기 조회: 사용자1 (1건)" GET /api/users/1/favorites
call 200 "즐겨찾기 조회: 사용자7 (2건, 영업종료 가게 포함)" GET /api/users/7/favorites
call 200 "즐겨찾기 조회: 사용자3 (빈 목록)" GET /api/users/3/favorites
call 404 "즐겨찾기 조회: 없는 사용자" GET /api/users/999/favorites
call 201 "즐겨찾기 추가: 사용자1 + 가게3" POST /api/users/1/favorites '{"storeId": 3}'
call 409 "즐겨찾기 추가: 중복" POST /api/users/1/favorites '{"storeId": 3}'
call 404 "즐겨찾기 추가: 없는 가게" POST /api/users/1/favorites '{"storeId": 999}'
call 400 "즐겨찾기 추가: storeId 문자열" POST /api/users/1/favorites '{"storeId": "abc"}'
call 404 "즐겨찾기 추가: 없는 사용자" POST /api/users/999/favorites '{"storeId": 3}'
call 204 "즐겨찾기 삭제: 사용자1 - 가게3" DELETE /api/users/1/favorites/3
call 404 "즐겨찾기 삭제: 이미 없음" DELETE /api/users/1/favorites/3
call 404 "즐겨찾기 삭제: 없는 사용자" DELETE /api/users/999/favorites/3

echo "===== 내 정보 · 요약 =====" | tee -a "$OUT"
call 200 "내 정보: 사용자1 (전화번호 마스킹)" GET /api/users/1
call 200 "내 정보: 사용자3 (전화번호 null)" GET /api/users/3
call 404 "내 정보: 없는 사용자" GET /api/users/999
call 200 "요약: 사용자1 (리뷰1, 도움1, 즐겨찾기1)" GET /api/users/1/summary
call 200 "요약: 사용자4 (리뷰2, 도움3, 즐겨찾기2)" GET /api/users/4/summary
call 200 "요약: 사용자3 (모두 0)" GET /api/users/3/summary
call 404 "요약: 없는 사용자" GET /api/users/999/summary

echo "===== 내 리뷰 =====" | tee -a "$OUT"
call 200 "내 리뷰 목록: 사용자4 (리뷰8, 리뷰3)" GET /api/users/4/reviews
call 200 "내 리뷰 목록: 사용자1 (리뷰1)" GET /api/users/1/reviews
call 200 "내 리뷰 목록: 사용자3 (빈 목록)" GET /api/users/3/reviews
call 404 "내 리뷰 목록: 없는 사용자" GET /api/users/999/reviews

echo "===== 도움됨 반응 =====" | tee -a "$OUT"
call 200 "도움됨 등록: 사용자1 -> 리뷰1 (true)" PUT /api/users/1/helpful-reviews/1 '{"isHelpful": true}'
call 200 "반영 확인: 사용자1 리뷰 (helpfulCount 2, myReaction true)" GET /api/users/1/reviews
call 200 "도움됨 변경: false" PUT /api/users/1/helpful-reviews/1 '{"isHelpful": false}'
call 200 "반영 확인: (helpfulCount 1, notHelpfulCount 2, myReaction false)" GET /api/users/1/reviews
call 400 "도움됨: isHelpful 문자열" PUT /api/users/1/helpful-reviews/1 '{"isHelpful": "true"}'
call 400 "도움됨: isHelpful 누락" PUT /api/users/1/helpful-reviews/1 '{}'
call 404 "도움됨: 없는 리뷰" PUT /api/users/1/helpful-reviews/999 '{"isHelpful": true}'
call 404 "도움됨: 없는 사용자" PUT /api/users/999/helpful-reviews/1 '{"isHelpful": true}'
call 204 "도움됨 취소: 사용자1 - 리뷰1" DELETE /api/users/1/helpful-reviews/1
call 404 "도움됨 취소: 이미 없음" DELETE /api/users/1/helpful-reviews/1
call 404 "도움됨 취소: 없는 사용자" DELETE /api/users/999/helpful-reviews/1

echo "===== 주소 =====" | tee -a "$OUT"
ADDR='{"addressLabel": "학교", "postalCode": "13120", "addressLine1": "테스트시 연습로 10", "addressLine2": "AI관"}'
call 200 "주소 목록: 사용자1 (집 기본 -> 회사)" GET /api/users/1/addresses
call 200 "주소 목록: 사용자3 (빈 목록)" GET /api/users/3/addresses
call 404 "주소 목록: 없는 사용자" GET /api/users/999/addresses
call 201 "주소 등록: 사용자1 (기본 아님)" POST /api/users/1/addresses "$ADDR"
NEW1=$(jget addressId)
call 201 "주소 등록: 사용자3 첫 주소 (자동 기본)" POST /api/users/3/addresses '{"addressLabel": "집", "addressLine1": "테스트시 연습로 11"}'
NEW3=$(jget addressId)
call 400 "주소 등록: addressLine1 누락" POST /api/users/1/addresses '{"addressLabel": "학교"}'
call 400 "주소 등록: 우편번호 형식 오류" POST /api/users/1/addresses '{"addressLabel": "학교", "postalCode": "123", "addressLine1": "주소"}'
call 404 "주소 등록: 없는 사용자" POST /api/users/999/addresses '{"addressLabel": "집", "addressLine1": "주소"}'
call 200 "주소 수정: 사용자1 - 방금 등록한 주소" PUT /api/users/1/addresses/$NEW1 '{"addressLabel": "학교(수정)", "postalCode": "13120", "addressLine1": "테스트시 연습로 10", "addressLine2": "AI관 2층"}'
call 404 "주소 수정: 다른 사용자의 주소(주소4)" PUT /api/users/1/addresses/4 "$ADDR"
call 404 "주소 수정: 없는 주소" PUT /api/users/1/addresses/999 "$ADDR"
call 400 "주소 수정: 입력 오류" PUT /api/users/1/addresses/$NEW1 '{"addressLabel": "학교"}'
call 200 "기본 주소 변경: 사용자1 -> 주소2" PUT /api/users/1/default-address '{"addressId": 2}'
call 200 "반영 확인: 회사가 기본, 집은 false" GET /api/users/1/addresses
call 404 "기본 주소 변경: 다른 사용자의 주소(주소4)" PUT /api/users/1/default-address '{"addressId": 4}'
call 400 "기본 주소 변경: addressId 문자열" PUT /api/users/1/default-address '{"addressId": "2"}'
call 404 "기본 주소 변경: 없는 사용자" PUT /api/users/999/default-address '{"addressId": 2}'
call 200 "기본 주소 원복: 사용자1 -> 주소1" PUT /api/users/1/default-address '{"addressId": 1}'
call 204 "주소 삭제: 사용자1 - 방금 등록한 주소" DELETE /api/users/1/addresses/$NEW1
call 404 "주소 삭제: 이미 없음" DELETE /api/users/1/addresses/$NEW1
call 404 "주소 삭제: 다른 사용자의 주소(주소4)" DELETE /api/users/1/addresses/4
call 404 "주소 삭제: 없는 사용자" DELETE /api/users/999/addresses/$NEW1
call 204 "주소 삭제: 사용자3 임시 주소 (원복)" DELETE /api/users/3/addresses/$NEW3

echo "===== 결과: PASS $PASS / FAIL $FAIL =====" | tee -a "$OUT"
