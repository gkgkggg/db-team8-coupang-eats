-- 담당: 마이이츠 담당 / View: 마이이츠·즐겨찾기
-- 백엔드(backend/my_page.py, backend/favorites.py)에서 사용하는 SQL 모음.
-- 코드의 %s 자리는 아래 변수로 표기했다. (테스트: 값을 바꿔 mysql에서 그대로 실행 가능)
-- 받은 도움 수는 내 리뷰의 ReviewHelpful.IsHelpful=TRUE만 집계한다.
-- FALSE는 '도움이 안 돼요', 행이 없으면 미참여다.

USE db_team8;
SET @user_id = 1;
SET @store_id = 2;
SET @review_id = 1;
SET @address_id = 1;

-- =========================================================
-- 1. 마이이츠: 사용자 정보 / 요약
-- =========================================================

-- 1-1. 사용자 정보 (전화번호 마스킹은 애플리케이션에서 처리)
SELECT UserID, UserName, UserPhone FROM Users WHERE UserID = @user_id;

-- 1-2. 요약: 리뷰 수 / 받은 도움 수 / 즐겨찾기 수
SELECT u.UserID, u.UserName, u.UserPhone,
       (SELECT COUNT(*)
          FROM Reviews r JOIN Orders o ON o.OrderID = r.OrderID
         WHERE o.UserID = u.UserID) AS reviewCount,
       (SELECT COUNT(*)
          FROM ReviewHelpful h
          JOIN Reviews r ON r.ReviewID = h.ReviewID
          JOIN Orders o ON o.OrderID = r.OrderID
         WHERE o.UserID = u.UserID AND h.IsHelpful = TRUE) AS helpfulCount,
       (SELECT COUNT(*) FROM Favorites f WHERE f.UserID = u.UserID) AS favoriteCount
  FROM Users u
 WHERE u.UserID = @user_id;

-- =========================================================
-- 2. 마이이츠: 내 리뷰 / 도움이 돼요
-- =========================================================

-- 2-1. 내 리뷰 목록 (도움 수, 안 도움 수, 내 반응)
SELECT r.ReviewID, r.OrderID, s.StoreID, s.StoreName, r.Rating, r.Content, r.CreatedAt,
       (SELECT COUNT(*) FROM ReviewHelpful h
         WHERE h.ReviewID = r.ReviewID AND h.IsHelpful = TRUE)  AS helpfulCount,
       (SELECT COUNT(*) FROM ReviewHelpful h
         WHERE h.ReviewID = r.ReviewID AND h.IsHelpful = FALSE) AS notHelpfulCount,
       (SELECT h.IsHelpful FROM ReviewHelpful h
         WHERE h.ReviewID = r.ReviewID AND h.UserID = @user_id) AS myReaction
  FROM Reviews r
  JOIN Orders o ON o.OrderID = r.OrderID
  JOIN Stores s ON s.StoreID = o.StoreID
 WHERE o.UserID = @user_id
 ORDER BY r.CreatedAt DESC;

-- 2-2. 도움이 돼요/안 돼요 등록·변경 (Upsert, 값은 TRUE 또는 FALSE)
INSERT INTO ReviewHelpful (UserID, ReviewID, IsHelpful)
VALUES (@user_id, @review_id, TRUE) AS new
ON DUPLICATE KEY UPDATE IsHelpful = new.IsHelpful;

-- 2-3. 반응 취소
DELETE FROM ReviewHelpful WHERE UserID = @user_id AND ReviewID = @review_id;

-- =========================================================
-- 3. 즐겨찾기
-- =========================================================

-- 3-1. 즐겨찾기 목록 (최근 추가 순)
SELECT s.StoreID, s.StoreName, s.StoreImageURL, s.MinimumOrderAmount,
       s.DeliveryFee, s.EstimatedDeliveryMinutes, s.IsOpen, f.CreatedAt AS favoritedAt
  FROM Favorites f
  JOIN Stores s ON s.StoreID = f.StoreID
 WHERE f.UserID = @user_id
 ORDER BY f.CreatedAt DESC;

-- 3-2. 즐겨찾기 추가 (이미 있으면 PK 중복으로 실패 → API에서 409)
INSERT INTO Favorites (UserID, StoreID) VALUES (@user_id, @store_id);

-- 3-3. 즐겨찾기 해제
DELETE FROM Favorites WHERE UserID = @user_id AND StoreID = @store_id;

-- =========================================================
-- 4. 배달 주소
-- =========================================================

-- 4-1. 주소 목록 (기본 주소 먼저)
SELECT AddressID, AddressLabel, PostalCode, AddressLine1, AddressLine2, IsDefault, CreatedAt
  FROM Addresses
 WHERE UserID = @user_id
 ORDER BY IsDefault DESC, CreatedAt ASC;

-- 4-2. 주소 추가 (첫 주소면 IsDefault=TRUE, 아니면 FALSE)
SELECT COUNT(*) AS c FROM Addresses WHERE UserID = @user_id;
INSERT INTO Addresses (UserID, AddressLabel, PostalCode, AddressLine1, AddressLine2, IsDefault)
VALUES (@user_id, '새 주소', '13120', '경기도 성남시 수정구 성남대로 1342', NULL, FALSE);

-- 4-3. 주소 수정 (본인 주소만)
UPDATE Addresses
   SET AddressLabel = '수정된 이름'
 WHERE AddressID = @address_id AND UserID = @user_id;

-- 4-4. 주소 삭제 (본인 주소만)
DELETE FROM Addresses WHERE AddressID = @address_id AND UserID = @user_id;

-- 4-5. 기본 주소 변경 (트랜잭션: 기존 기본 해제 → 새 기본 설정)
--      사용자당 기본 주소 1개 제약 때문에 순서를 지켜야 한다.
START TRANSACTION;
UPDATE Addresses SET IsDefault = FALSE WHERE UserID = @user_id AND IsDefault = TRUE;
UPDATE Addresses SET IsDefault = TRUE  WHERE AddressID = @address_id AND UserID = @user_id;
COMMIT;
