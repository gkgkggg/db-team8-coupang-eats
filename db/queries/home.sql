-- 담당: 홈 담당 / View: 홈
-- API: GET /api/home, GET /api/categories, GET /api/stores, GET /api/stores/{storeId}, GET /api/stores/{storeId}/menus
-- MySQL Workbench에서 아래 SET 값을 바꿔 실행한다. 서버는 같은 SQL을 ? 바인딩으로 실행한다.
-- GET /api/home = 0번(사용자 확인·선택 주소) + 1번(카테고리) + 2번(가게 목록)을 한 응답으로 묶는다.

USE db_team8;
SET NAMES utf8mb4;

SET @userId = 1;
SET @categoryId = 2;      -- NULL이면 전체 카테고리
SET @keyword = '치킨';     -- NULL이면 검색 안 함
SET @storeId = 1;

-- 0. 홈 선택 주소: GET /api/home
-- 사용자가 없으면 404. 기본 주소가 없으면(삭제 등) address는 null로 반환한다.
SELECT UserID FROM Users WHERE UserID = @userId;

SELECT AddressID, AddressLabel, PostalCode, AddressLine1, AddressLine2
FROM Addresses
WHERE UserID = @userId AND IsDefault = TRUE;

-- 1. 카테고리 목록: GET /api/categories
SELECT CategoryID, CategoryName, CategoryImageURL, DisplayOrder
FROM Categories
ORDER BY DisplayOrder, CategoryID;

-- 2. 가게 목록: GET /api/stores?categoryId=&keyword=&sort=
-- 별점·리뷰 수는 Reviews–Orders를 가게별로 먼저 집계한 뒤 LEFT JOIN한다.
-- (리뷰 없는 가게도 목록에 남고, 조인으로 행이 늘어 COUNT가 부풀지 않는다.)
-- 카테고리 필터는 IN 서브쿼리로 걸어 가게가 여러 카테고리에 속해도 한 번만 나온다.
SELECT s.StoreID, s.StoreName, s.StoreImageURL, s.DeliveryFee, s.MinimumOrderAmount,
       s.EstimatedDeliveryMinutes, s.IsOpen,
       r.AvgRating, COALESCE(r.ReviewCount, 0) AS ReviewCount
FROM Stores s
LEFT JOIN (
    SELECT o.StoreID, ROUND(AVG(rv.Rating), 1) AS AvgRating, COUNT(*) AS ReviewCount
    FROM Reviews rv
    JOIN Orders o ON o.OrderID = rv.OrderID
    GROUP BY o.StoreID
) r ON r.StoreID = s.StoreID
WHERE (@categoryId IS NULL
       OR s.StoreID IN (SELECT sc.StoreID FROM StoreCategories sc WHERE sc.CategoryID = @categoryId))
  AND (@keyword IS NULL OR s.StoreName LIKE CONCAT('%', @keyword, '%'))
ORDER BY s.StoreName, s.StoreID;                                  -- sort=name (기본)
-- ORDER BY s.DeliveryFee, s.StoreID;                             -- sort=deliveryFee
-- ORDER BY r.AvgRating IS NULL, r.AvgRating DESC,
--          ReviewCount DESC, s.StoreID;                          -- sort=rating (리뷰 없는 가게는 뒤로)

-- 2-1. categoryId 존재 확인 (없으면 404)
SELECT CategoryID FROM Categories WHERE CategoryID = @categoryId;

-- 3. 가게 상세: GET /api/stores/{storeId}
SELECT s.StoreID, s.StoreName, s.StorePhone, s.StoreAddress, s.StoreImageURL,
       s.DeliveryFee, s.MinimumOrderAmount, s.EstimatedDeliveryMinutes, s.IsOpen,
       r.AvgRating, COALESCE(r.ReviewCount, 0) AS ReviewCount
FROM Stores s
LEFT JOIN (
    SELECT o.StoreID, ROUND(AVG(rv.Rating), 1) AS AvgRating, COUNT(*) AS ReviewCount
    FROM Reviews rv
    JOIN Orders o ON o.OrderID = rv.OrderID
    WHERE o.StoreID = @storeId
    GROUP BY o.StoreID
) r ON r.StoreID = s.StoreID
WHERE s.StoreID = @storeId;

-- 4. 가게 메뉴: GET /api/stores/{storeId}/menus
-- 가게가 없으면 404이므로 3번(또는 아래 존재 확인)을 먼저 실행한다. 판매 중지 메뉴도 IsAvailable과 함께 반환한다.
SELECT StoreID FROM Stores WHERE StoreID = @storeId;

SELECT MenuID, MenuName, CurrentPrice, MenuImageURL, IsAvailable
FROM Menus
WHERE StoreID = @storeId
ORDER BY MenuID;
