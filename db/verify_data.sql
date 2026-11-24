-- data.sql을 실행한 직후 확인한다. 모든 행의 Result가 PASS여야 한다.
USE `db_team8`;
SET NAMES utf8mb4;

-- 첫 11행은 테이블별 대표 행에서 모든 컬럼 값을 확인한다.
-- 이후에는 여러 행이나 테이블을 연결해야 볼 수 있는 화면 사례를 확인한다.
WITH StoreReviews AS (
    SELECT o.StoreID, COUNT(r.ReviewID) AS ReviewCount, AVG(r.Rating) AS AverageRating
    FROM Orders AS o
    LEFT JOIN Reviews AS r ON r.OrderID = o.OrderID
    GROUP BY o.StoreID
), FoodImages AS (
    SELECT CategoryImageURL AS ImageURL FROM Categories WHERE CategoryImageURL IS NOT NULL
    UNION
    SELECT StoreImageURL FROM Stores WHERE StoreImageURL IS NOT NULL
    UNION
    SELECT MenuImageURL FROM Menus WHERE MenuImageURL IS NOT NULL
)
SELECT 1 AS CheckNo, 'Users' AS CheckName, 4 AS ColumnsChecked,
    IF(EXISTS (
        SELECT 1 FROM Users
        WHERE UserID = 1 AND UserName = '테스트 사용자 A' AND UserPhone = '010-0000-0001'
          AND CreatedAt = '2026-11-01 09:00:00'
    ), 'PASS', 'FAIL') AS Result
UNION ALL
SELECT 2, 'Addresses', 8, IF(EXISTS (
    SELECT 1 FROM Addresses
    WHERE AddressID = 1 AND UserID = 1 AND AddressLabel = '집' AND PostalCode = '01234'
      AND AddressLine1 = '테스트시 연습로 1' AND AddressLine2 = '101호'
      AND IsDefault = TRUE AND CreatedAt = '2026-11-01 09:05:00'
), 'PASS', 'FAIL')
UNION ALL
SELECT 3, 'Categories', 4, IF(EXISTS (
    SELECT 1 FROM Categories
    WHERE CategoryID = 2 AND CategoryName = '치킨'
      AND CategoryImageURL = 'https://raw.githubusercontent.com/gkgkggg/db-team8-coupang-eats/main/db/fixtures/food/fried-chicken.jpg'
      AND DisplayOrder = 10
), 'PASS', 'FAIL')
UNION ALL
SELECT 4, 'Stores', 9, IF(EXISTS (
    SELECT 1 FROM Stores
    WHERE StoreID = 1 AND StoreName = '테스트 치킨집' AND StorePhone = '02-000-0001'
      AND StoreAddress = '테스트시 가게로 1'
      AND StoreImageURL = 'https://raw.githubusercontent.com/gkgkggg/db-team8-coupang-eats/main/db/fixtures/food/fried-chicken.jpg'
      AND MinimumOrderAmount = 12000 AND DeliveryFee = 2500
      AND EstimatedDeliveryMinutes = 30 AND IsOpen = TRUE
), 'PASS', 'FAIL')
UNION ALL
SELECT 5, 'StoreCategories', 2, IF(EXISTS (
    SELECT 1 FROM StoreCategories WHERE StoreID = 1 AND CategoryID = 2
), 'PASS', 'FAIL')
UNION ALL
SELECT 6, 'Menus', 6, IF(EXISTS (
    SELECT 1 FROM Menus
    WHERE MenuID = 1 AND StoreID = 1 AND MenuName = '바삭 치킨' AND CurrentPrice = 18000
      AND MenuImageURL = 'https://raw.githubusercontent.com/gkgkggg/db-team8-coupang-eats/main/db/fixtures/food/fried-chicken.jpg'
      AND IsAvailable = TRUE
), 'PASS', 'FAIL')
UNION ALL
SELECT 7, 'Favorites', 3, IF(EXISTS (
    SELECT 1 FROM Favorites WHERE UserID = 1 AND StoreID = 1 AND CreatedAt = '2026-11-02 10:00:00'
), 'PASS', 'FAIL')
UNION ALL
SELECT 8, 'Orders', 8, IF(EXISTS (
    SELECT 1 FROM Orders
    WHERE OrderID = 101 AND UserID = 1 AND StoreID = 1 AND OrderedAt = '2026-11-10 18:30:00'
      AND OrderStatus = 'completed' AND DeliveryAddressText = '테스트시 이전로 9 101호'
      AND DeliveryFee = 2000 AND DiscountAmount = 1000
), 'PASS', 'FAIL')
UNION ALL
SELECT 9, 'OrderItems', 5, IF(EXISTS (
    SELECT 1 FROM OrderItems
    WHERE OrderID = 101 AND MenuID = 1 AND Quantity = 2
      AND UnitPriceAtOrder = 17000 AND MenuNameAtOrder = '후라이드 치킨'
), 'PASS', 'FAIL')
UNION ALL
SELECT 10, 'Reviews', 5, IF(EXISTS (
    SELECT 1 FROM Reviews
    WHERE ReviewID = 1 AND OrderID = 101 AND Rating = 5 AND Content = '바삭하고 따뜻했어요.'
      AND CreatedAt = '2026-11-10 20:00:00'
), 'PASS', 'FAIL')
UNION ALL
SELECT 11, 'ReviewHelpful', 4, IF(EXISTS (
    SELECT 1 FROM ReviewHelpful
    WHERE UserID = 2 AND ReviewID = 1 AND IsHelpful = TRUE AND CreatedAt = '2026-11-12 09:00:00'
), 'PASS', 'FAIL')
UNION ALL
SELECT 12, '리뷰 있는 가게와 없는 가게', NULL, IF(
    EXISTS (SELECT 1 FROM StoreReviews WHERE StoreID = 1 AND ReviewCount = 2 AND AverageRating = 4.5)
    AND EXISTS (SELECT 1 FROM StoreReviews WHERE StoreID = 3 AND ReviewCount = 0 AND AverageRating IS NULL)
    AND EXISTS (SELECT 1 FROM Orders WHERE StoreID = 3 AND OrderStatus = 'completed'),
    'PASS', 'FAIL')
UNION ALL
SELECT 13, '영업 중과 영업 종료', NULL, IF(
    EXISTS (SELECT 1 FROM Stores WHERE StoreID = 1 AND IsOpen = TRUE)
    AND EXISTS (SELECT 1 FROM Stores WHERE StoreID = 2 AND IsOpen = FALSE),
    'PASS', 'FAIL')
UNION ALL
SELECT 14, '가게 하나에 서로 다른 카테고리 두 개', NULL, IF(EXISTS (
    SELECT sc.StoreID FROM StoreCategories AS sc
    JOIN Categories AS c ON c.CategoryID = sc.CategoryID
    WHERE sc.StoreID = 1
    GROUP BY sc.StoreID
    HAVING COUNT(*) = 2 AND SUM(c.CategoryName IN ('한식', '치킨')) = 2
), 'PASS', 'FAIL')
UNION ALL
SELECT 15, '같은 가게의 판매 가능 메뉴와 품절 메뉴', NULL, IF(
    EXISTS (SELECT 1 FROM Menus WHERE MenuID = 1 AND StoreID = 1 AND IsAvailable = TRUE)
    AND EXISTS (SELECT 1 FROM Menus WHERE MenuID = 2 AND StoreID = 1 AND IsAvailable = FALSE),
    'PASS', 'FAIL')
UNION ALL
SELECT 16, '기본 주소 있음, 미지정, 주소 없음', NULL, IF(
    (SELECT COUNT(*) FROM Addresses WHERE UserID = 1 AND IsDefault = TRUE) = 1
    AND EXISTS (SELECT 1 FROM Addresses WHERE UserID = 2 AND IsDefault = FALSE)
    AND NOT EXISTS (SELECT 1 FROM Addresses WHERE UserID = 2 AND IsDefault = TRUE)
    AND EXISTS (SELECT 1 FROM Users WHERE UserID = 3)
    AND NOT EXISTS (SELECT 1 FROM Addresses WHERE UserID = 3),
    'PASS', 'FAIL')
UNION ALL
SELECT 17, '선택 컬럼의 NULL 입력', NULL, IF(
    EXISTS (SELECT 1 FROM Users WHERE UserID = 3 AND UserPhone IS NULL)
    AND EXISTS (SELECT 1 FROM Addresses WHERE AddressID = 3 AND PostalCode IS NULL AND AddressLine2 IS NULL)
    AND EXISTS (SELECT 1 FROM Categories WHERE CategoryID = 3 AND CategoryImageURL IS NULL)
    AND EXISTS (SELECT 1 FROM Stores WHERE StoreID = 2 AND StoreImageURL IS NULL)
    AND EXISTS (SELECT 1 FROM Stores WHERE StoreID = 3 AND StorePhone IS NULL AND EstimatedDeliveryMinutes IS NULL)
    AND EXISTS (SELECT 1 FROM Menus WHERE MenuID = 2 AND MenuImageURL IS NULL)
    AND EXISTS (SELECT 1 FROM Reviews WHERE ReviewID = 2 AND Content IS NULL),
    'PASS', 'FAIL')
UNION ALL
SELECT 18, '1번 사용자의 주문 상태 네 가지', NULL, IF(
    (SELECT COUNT(DISTINCT OrderStatus) FROM Orders WHERE UserID = 1) = 4,
    'PASS', 'FAIL')
UNION ALL
SELECT 19, '주문 당시 메뉴명, 단가, 주소, 배달비와 합계', NULL, IF(
    EXISTS (
        SELECT 1 FROM OrderItems AS oi
        JOIN Menus AS m ON m.MenuID = oi.MenuID
        JOIN Orders AS o ON o.OrderID = oi.OrderID
        JOIN Stores AS s ON s.StoreID = o.StoreID
        JOIN Addresses AS a ON a.UserID = o.UserID AND a.IsDefault = TRUE
        WHERE oi.OrderID = 101 AND oi.MenuID = 1
          AND oi.MenuNameAtOrder <> m.MenuName AND oi.UnitPriceAtOrder <> m.CurrentPrice
          AND o.DeliveryAddressText <> CONCAT_WS(' ', a.AddressLine1, a.AddressLine2)
          AND o.DeliveryFee <> s.DeliveryFee
    )
    AND EXISTS (
        SELECT o.OrderID FROM Orders AS o
        JOIN OrderItems AS oi ON oi.OrderID = o.OrderID
        WHERE o.OrderID = 101
        GROUP BY o.OrderID, o.DeliveryFee, o.DiscountAmount
        HAVING SUM(oi.Quantity * oi.UnitPriceAtOrder) + o.DeliveryFee - o.DiscountAmount = 53500
    ), 'PASS', 'FAIL')
UNION ALL
SELECT 20, '도움, 비도움, 반응 없음', NULL, IF(
    EXISTS (SELECT 1 FROM ReviewHelpful WHERE UserID = 2 AND ReviewID = 1 AND IsHelpful = TRUE)
    AND EXISTS (SELECT 1 FROM ReviewHelpful WHERE UserID = 3 AND ReviewID = 1 AND IsHelpful = FALSE)
    AND EXISTS (SELECT 1 FROM Reviews WHERE ReviewID = 2)
    AND NOT EXISTS (SELECT 1 FROM ReviewHelpful WHERE ReviewID = 2),
    'PASS', 'FAIL')
UNION ALL
SELECT 21, '즐겨찾기 조회와 추가 테스트 대상', NULL, IF(
    EXISTS (SELECT 1 FROM Favorites WHERE UserID = 1 AND StoreID = 1)
    AND EXISTS (SELECT 1 FROM Stores WHERE StoreID = 3)
    AND NOT EXISTS (SELECT 1 FROM Favorites WHERE UserID = 1 AND StoreID = 3),
    'PASS', 'FAIL')
UNION ALL
SELECT 22, '서로 다른 음식 사진 8개', NULL, IF(
    (SELECT COUNT(*) FROM FoodImages) = 8
    AND NOT EXISTS (
        SELECT 1 FROM FoodImages
        WHERE NOT REGEXP_LIKE(ImageURL,
            '^https://raw[.]githubusercontent[.]com/gkgkggg/db-team8-coupang-eats/main/db/fixtures/food/[a-z-]+[.]jpg$', 'c')
    ), 'PASS', 'FAIL')
UNION ALL
SELECT 23, '평점 1~5점, 무료 배달, 복수 가게와 품절 메뉴', NULL, IF(
    (SELECT COUNT(DISTINCT Rating) FROM Reviews) = 5
    AND EXISTS (SELECT 1 FROM Stores WHERE DeliveryFee = 0 AND IsOpen = TRUE)
    AND (SELECT COUNT(*) FROM Stores WHERE IsOpen = FALSE) >= 2
    AND (SELECT COUNT(DISTINCT StoreID) FROM Menus WHERE IsAvailable = FALSE) >= 2,
    'PASS', 'FAIL')
UNION ALL
SELECT 24, '주문과 메뉴의 가게 일치, 완료 주문의 리뷰', NULL, IF(
    EXISTS (SELECT 1 FROM Orders) AND EXISTS (SELECT 1 FROM Reviews)
    AND NOT EXISTS (
        SELECT 1 FROM Orders AS o
        WHERE NOT EXISTS (SELECT 1 FROM OrderItems AS oi WHERE oi.OrderID = o.OrderID)
    )
    AND NOT EXISTS (
        SELECT 1 FROM OrderItems AS oi
        JOIN Orders AS o ON o.OrderID = oi.OrderID
        JOIN Menus AS m ON m.MenuID = oi.MenuID
        WHERE o.StoreID <> m.StoreID
    )
    AND NOT EXISTS (
        SELECT 1 FROM Reviews AS r JOIN Orders AS o ON o.OrderID = r.OrderID
        WHERE o.OrderStatus <> 'completed'
    ), 'PASS', 'FAIL')
ORDER BY CheckNo;
