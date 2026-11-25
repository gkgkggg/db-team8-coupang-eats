-- 담당: 주문내역 담당 / View: 주문내역
-- 작성할 SQL: 주문·메뉴·금액·리뷰 여부 조회, 상태 필터 (db_team8 / MySQL 8.0+)

-- =====================================================================
-- 1. 사용자 검증 및 미작성 리뷰 수 집계
-- =====================================================================

-- 사용자 존재 여부 확인 (없는 UserID 조회 시 404 예외 처리용)
-- [check_user_exists]
SELECT UserID, UserName
FROM Users
WHERE UserID = ?;

-- 주문내역 상단 배너 표시용 미작성 리뷰 건수 조회
-- 조건: 해당 사용자의 배달 완료(completed) 주문 중 Reviews 테이블에 아직 등록되지 않은 주문 수
-- [get_unwritten_review_count]
SELECT COUNT(*) AS unwrittenReviewCount
FROM Orders o
LEFT JOIN Reviews r ON o.OrderID = r.OrderID
WHERE o.UserID = ?
  AND o.OrderStatus = 'completed'
  AND r.ReviewID IS NULL;


-- =====================================================================
-- 2. 사용자별 주문 목록 조회 (전체 최신순 & 주문 상태별 필터)
-- =====================================================================

-- 사용자 전체 주문 목록 최신순 조회 (과거 주문·진행 중·취소 전체 포함)
-- 내용: 가게 정보, 대표 메뉴명(MenuID 오름차순 첫 번째 스냅샷), 추가 메뉴 수('외 N개'),
--       주문 당시 단가 기준 총 결제금액(메뉴 소계 + 배달비 - 할인액), 리뷰 작성 여부 조회
-- [get_user_orders_all]
SELECT 
    o.OrderID,
    o.UserID,
    s.StoreID,
    s.StoreName,
    s.StoreImageURL,
    o.OrderedAt,
    o.OrderStatus,
    o.DeliveryFee,
    o.DiscountAmount,
    (
        SELECT oi2.MenuNameAtOrder
        FROM OrderItems oi2
        WHERE oi2.OrderID = o.OrderID
        ORDER BY oi2.MenuID ASC
        LIMIT 1
    ) AS representativeMenuName,
    GREATEST(COUNT(oi.MenuID) - 1, 0) AS extraMenuCount,
    COALESCE(SUM(oi.Quantity * oi.UnitPriceAtOrder), 0) AS menuSubtotal,
    COALESCE(SUM(oi.Quantity * oi.UnitPriceAtOrder), 0) + o.DeliveryFee - o.DiscountAmount AS totalAmount,
    r.ReviewID,
    CASE WHEN r.ReviewID IS NOT NULL THEN TRUE ELSE FALSE END AS hasReview
FROM Orders o
JOIN Stores s ON o.StoreID = s.StoreID
LEFT JOIN OrderItems oi ON o.OrderID = oi.OrderID
LEFT JOIN Reviews r ON o.OrderID = r.OrderID
WHERE o.UserID = ?
GROUP BY 
    o.OrderID, o.UserID, s.StoreID, s.StoreName, s.StoreImageURL,
    o.OrderedAt, o.OrderStatus, o.DeliveryFee, o.DiscountAmount, r.ReviewID
ORDER BY o.OrderedAt DESC, o.OrderID DESC;

-- 주문 상태별 필터링 목록 최신순 조회
-- 조건: OrderStatus가 'preparing'(준비중), 'delivering'(배달중), 'completed'(완료), 'cancelled'(취소) 중 일치하는 항목만 반환
-- [get_user_orders_by_status]
SELECT 
    o.OrderID,
    o.UserID,
    s.StoreID,
    s.StoreName,
    s.StoreImageURL,
    o.OrderedAt,
    o.OrderStatus,
    o.DeliveryFee,
    o.DiscountAmount,
    (
        SELECT oi2.MenuNameAtOrder
        FROM OrderItems oi2
        WHERE oi2.OrderID = o.OrderID
        ORDER BY oi2.MenuID ASC
        LIMIT 1
    ) AS representativeMenuName,
    GREATEST(COUNT(oi.MenuID) - 1, 0) AS extraMenuCount,
    COALESCE(SUM(oi.Quantity * oi.UnitPriceAtOrder), 0) AS menuSubtotal,
    COALESCE(SUM(oi.Quantity * oi.UnitPriceAtOrder), 0) + o.DeliveryFee - o.DiscountAmount AS totalAmount,
    r.ReviewID,
    CASE WHEN r.ReviewID IS NOT NULL THEN TRUE ELSE FALSE END AS hasReview
FROM Orders o
JOIN Stores s ON o.StoreID = s.StoreID
LEFT JOIN OrderItems oi ON o.OrderID = oi.OrderID
LEFT JOIN Reviews r ON o.OrderID = r.OrderID
WHERE o.UserID = ?
  AND o.OrderStatus = ?
GROUP BY 
    o.OrderID, o.UserID, s.StoreID, s.StoreName, s.StoreImageURL,
    o.OrderedAt, o.OrderStatus, o.DeliveryFee, o.DiscountAmount, r.ReviewID
ORDER BY o.OrderedAt DESC, o.OrderID DESC;


-- =====================================================================
-- 3. 주문 상세 내역 조회 (주문 기본·결제 정보 및 주문 항목 목록)
-- =====================================================================

-- 특정 주문의 상세 요약 정보 조회
-- 내용: 가게 상세 정보, 주문 일시, 주문 상태, 주문 당시 배달 주소, 결제 금액 합계, 리뷰 등록 여부
-- [get_order_detail_header]
SELECT 
    o.OrderID,
    o.UserID,
    s.StoreID,
    s.StoreName,
    s.StorePhone,
    s.StoreAddress,
    s.StoreImageURL,
    o.OrderedAt,
    o.OrderStatus,
    o.DeliveryAddressText,
    COALESCE(SUM(oi.Quantity * oi.UnitPriceAtOrder), 0) AS menuSubtotal,
    o.DeliveryFee,
    o.DiscountAmount,
    COALESCE(SUM(oi.Quantity * oi.UnitPriceAtOrder), 0) + o.DeliveryFee - o.DiscountAmount AS totalAmount,
    r.ReviewID,
    CASE WHEN r.ReviewID IS NOT NULL THEN TRUE ELSE FALSE END AS hasReview
FROM Orders o
JOIN Stores s ON o.StoreID = s.StoreID
LEFT JOIN OrderItems oi ON o.OrderID = oi.OrderID
LEFT JOIN Reviews r ON o.OrderID = r.OrderID
WHERE o.OrderID = ?
GROUP BY 
    o.OrderID, o.UserID, s.StoreID, s.StoreName, s.StorePhone, s.StoreAddress, s.StoreImageURL,
    o.OrderedAt, o.OrderStatus, o.DeliveryAddressText, o.DeliveryFee, o.DiscountAmount, r.ReviewID;

-- 특정 주문에 포함된 상세 메뉴 항목 리스트 조회
-- 내용: 주문 당시 메뉴명(MenuNameAtOrder) 및 단가(UnitPriceAtOrder) 스냅샷과 현재 메뉴 상태(Menus) 조인
-- [get_order_detail_items]
SELECT 
    oi.MenuID,
    oi.MenuNameAtOrder,
    m.MenuName AS currentMenuName,
    m.MenuImageURL,
    m.IsAvailable,
    oi.Quantity,
    oi.UnitPriceAtOrder,
    (oi.Quantity * oi.UnitPriceAtOrder) AS itemSubtotal
FROM OrderItems oi
JOIN Menus m ON oi.MenuID = m.MenuID
WHERE oi.OrderID = ?
ORDER BY oi.MenuID ASC;


-- =====================================================================
-- 4. 주문 리뷰 조회 · 작성 · 수정 · 삭제 (ReviewHelpful 연쇄 삭제 포함)
-- =====================================================================

-- 특정 주문번호(OrderID)에 작성된 리뷰 단건 조회
-- [get_review_by_order_id]
SELECT 
    r.ReviewID,
    r.OrderID,
    o.UserID,
    o.StoreID,
    r.Rating,
    r.Content,
    r.CreatedAt
FROM Reviews r
JOIN Orders o ON r.OrderID = o.OrderID
WHERE r.OrderID = ?;

-- 리뷰 작성 전 유효성 검증용 주문 조회
-- 검증 항목: 주문 존재 여부(404), 배달 완료(completed) 상태 여부(400), 기존 리뷰 중복 작성 여부(409)
-- [check_order_for_review]
SELECT 
    o.OrderID,
    o.UserID,
    o.StoreID,
    o.OrderStatus,
    r.ReviewID AS existingReviewId
FROM Orders o
LEFT JOIN Reviews r ON o.OrderID = r.OrderID
WHERE o.OrderID = ?;

-- 완료된 주문에 신규 리뷰 등록 (별점 1~5, 내용)
-- [insert_review]
INSERT INTO Reviews (OrderID, Rating, Content)
VALUES (?, ?, ?);

-- 리뷰 고유번호(ReviewID) 기준 리뷰 단건 조회 (작성·수정 직후 응답 반환 및 수정·삭제 전 존재 확인용)
-- [get_review_by_id]
SELECT 
    r.ReviewID,
    r.OrderID,
    o.UserID,
    o.StoreID,
    r.Rating,
    r.Content,
    r.CreatedAt
FROM Reviews r
JOIN Orders o ON r.OrderID = o.OrderID
WHERE r.ReviewID = ?;

-- 기존 리뷰의 별점 및 내용 수정
-- [update_review]
UPDATE Reviews
SET Rating = ?,
    Content = ?
WHERE ReviewID = ?;

-- 리뷰 삭제 시 해당 리뷰에 연결된 '도움이 돼요/안 돼요' 반응(ReviewHelpful) 선행 삭제
-- [delete_review_helpful_by_review_id]
DELETE FROM ReviewHelpful
WHERE ReviewID = ?;

-- 리뷰 본문 레코드 삭제
-- [delete_review]
DELETE FROM Reviews
WHERE ReviewID = ?;