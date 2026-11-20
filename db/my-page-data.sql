USE db_team8;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM ReviewHelpful;
DELETE FROM Reviews;
DELETE FROM OrderItems;
DELETE FROM Orders;
DELETE FROM Favorites;
DELETE FROM Menus;
DELETE FROM StoreCategories;
DELETE FROM Stores;
DELETE FROM Categories;
DELETE FROM Addresses;
DELETE FROM Users;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Users (UserID, UserName, UserPhone, CreatedAt) VALUES
(1, '사용자A', '010-1111-1234', '2026-09-01 10:00:00'),
(2, '사용자B', '010-2222-5678', '2026-09-05 12:30:00'),
(3, '사용자C', '010-3333-9012', '2026-09-10 18:20:00'),
(4, '사용자D', NULL,            '2026-09-15 09:10:00');

INSERT INTO Addresses (AddressID, UserID, AddressLabel, PostalCode, AddressLine1, AddressLine2, IsDefault, CreatedAt) VALUES
(1, 1, '집',     '13120', '경기도 성남시 수정구 성남대로 1342', '101동 1001호', TRUE,  '2026-09-01 10:05:00'),
(2, 1, '회사',   '13529', '경기도 성남시 분당구 판교로 235',    '5층',          FALSE, '2026-09-02 09:00:00'),
(3, 1, '부모님', '16490', '경기도 수원시 영통구 매탄로 10',     NULL,           FALSE, '2026-09-03 20:00:00'),
(4, 2, '집',     '06236', '서울특별시 강남구 테헤란로 152',     '302호',        TRUE,  '2026-09-05 12:35:00'),
(5, 3, '집',     '13120', '경기도 성남시 수정구 산성대로 100',  NULL,           TRUE,  '2026-09-10 18:25:00');

INSERT INTO Categories (CategoryID, CategoryName, CategoryImageURL, DisplayOrder) VALUES
(1, '치킨',       'images/category/chicken.png', 1),
(2, '피자',       'images/category/pizza.png',   2),
(3, '한식',       'images/category/korean.png',  3),
(4, '카페·디저트','images/category/cafe.png',    4),
(5, '버거',       'images/category/burger.png',  5);

INSERT INTO Stores (StoreID, StoreName, StorePhone, StoreAddress, StoreImageURL, MinimumOrderAmount, DeliveryFee, EstimatedDeliveryMinutes, IsOpen) VALUES
(1, '바삭치킨 성남점',   '031-111-0001', '경기도 성남시 수정구 성남대로 1300', 'images/store/1.png', 15000, 3000, 35, TRUE),
(2, '화덕피자 하우스',   '031-111-0002', '경기도 성남시 수정구 산성대로 50',   'images/store/2.png', 15000, 2500, 40, TRUE),
(3, '엄마손 한식당',     '031-111-0003', '경기도 성남시 수정구 복정로 20',     'images/store/3.png', 9000,  2000, 30, TRUE),
(4, '달콤 카페',         NULL,           '경기도 성남시 수정구 태평로 7',      'images/store/4.png', 5000,  0,    20, TRUE),
(5, '수제버거 랩',       '031-111-0005', '경기도 성남시 수정구 신흥로 33',     'images/store/5.png', 10000, 3500, 25, TRUE),
(6, '새벽치킨',          '031-111-0006', '경기도 성남시 중원구 광명로 12',     NULL,                 17000, 1000, 45, TRUE),
(7, '옛날 분식',         '031-111-0007', '경기도 성남시 수정구 수정로 88',     'images/store/7.png', 8000,  3000, NULL, FALSE),
(8, '든든 한식 도시락',  '031-111-0008', '경기도 성남시 분당구 서현로 4',      'images/store/8.png', 8000,  2500, 30, TRUE);

INSERT INTO StoreCategories (StoreID, CategoryID) VALUES
(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 1), (7, 3), (8, 3), (8, 5);

INSERT INTO Menus (MenuID, StoreID, MenuName, CurrentPrice, MenuImageURL, IsAvailable) VALUES
(1,  1, '후라이드치킨',   18000, 'images/menu/1.png',  TRUE),
(2,  1, '양념치킨',       19000, 'images/menu/2.png',  TRUE),
(3,  1, '콜라 1.25L',      2000, NULL,                 TRUE),
(4,  2, '치즈피자',       16900, 'images/menu/4.png',  TRUE),
(5,  2, '불고기피자',     18900, 'images/menu/5.png',  TRUE),
(6,  3, '김치찌개',        9000, 'images/menu/6.png',  TRUE),
(7,  3, '제육볶음',       10000, 'images/menu/7.png',  TRUE),
(8,  3, '공기밥',          1000, NULL,                 TRUE),
(9,  4, '아메리카노',      4500, 'images/menu/9.png',  TRUE),
(10, 4, '치즈케이크',      6500, 'images/menu/10.png', TRUE),
(11, 5, '클래식버거',      8900, 'images/menu/11.png', TRUE),
(12, 5, '감자튀김',        3500, NULL,                 TRUE),
(13, 6, '반반치킨',       20000, 'images/menu/13.png', TRUE),
(14, 6, '치킨무',           500, NULL,                 FALSE),
(15, 7, '떡볶이',          5000, 'images/menu/15.png', TRUE),
(16, 7, '순대',            4500, NULL,                 TRUE),
(17, 8, '불고기 도시락',   7500, 'images/menu/17.png', TRUE),
(18, 8, '제육 도시락',     7500, 'images/menu/18.png', TRUE);

INSERT INTO Favorites (UserID, StoreID, CreatedAt) VALUES
(1, 1, '2026-10-01 12:00:00'),
(1, 3, '2026-10-05 18:30:00'),
(1, 5, '2026-10-20 13:10:00'),
(1, 7, '2026-11-01 19:00:00'),
(2, 2, '2026-10-10 20:00:00'),
(2, 3, '2026-10-12 11:00:00');

INSERT INTO Orders (OrderID, UserID, StoreID, OrderedAt, OrderStatus, DeliveryAddressText, DeliveryFee, DiscountAmount) VALUES
(1, 1, 1, '2026-10-02 19:00:00', 'completed',  '경기도 성남시 수정구 성남대로 1342 101동 1001호', 3000, 0),
(2, 1, 2, '2026-10-08 20:10:00', 'completed',  '경기도 성남시 수정구 성남대로 1342 101동 1001호', 2500, 1000),
(3, 1, 3, '2026-10-15 12:30:00', 'completed',  '경기도 성남시 분당구 판교로 235 5층',              2000, 0),
(4, 1, 1, '2026-11-10 18:40:00', 'delivering', '경기도 성남시 수정구 성남대로 1342 101동 1001호', 3000, 0),
(5, 1, 4, '2026-11-05 15:00:00', 'cancelled',  '경기도 성남시 분당구 판교로 235 5층',              0,    0),
(6, 2, 1, '2026-10-11 19:20:00', 'completed',  '서울특별시 강남구 테헤란로 152 302호',             3000, 0),
(7, 2, 3, '2026-10-18 13:00:00', 'completed',  '서울특별시 강남구 테헤란로 152 302호',             2000, 0),
(8, 3, 2, '2026-10-20 21:00:00', 'completed',  '경기도 성남시 수정구 산성대로 100',                2500, 0);

INSERT INTO OrderItems (OrderID, MenuID, Quantity, UnitPriceAtOrder, MenuNameAtOrder) VALUES
(1, 1, 1, 18000, '후라이드치킨'),
(1, 3, 1,  2000, '콜라 1.25L'),
(2, 5, 1, 18900, '불고기피자'),
(3, 7, 1, 10000, '제육볶음'),
(3, 8, 2,  1000, '공기밥'),
(4, 2, 1, 19000, '양념치킨'),
(4, 3, 2,  2000, '콜라 1.25L'),
(5, 9, 2,  4500, '아메리카노'),
(5, 10, 1, 6500, '치즈케이크'),
(6, 1, 1, 18000, '후라이드치킨'),
(7, 7, 1, 10000, '제육볶음'),
(7, 8, 2,  1000, '공기밥'),
(8, 5, 1, 18900, '불고기피자');

INSERT INTO Reviews (ReviewID, OrderID, Rating, Content, CreatedAt) VALUES
(1, 1, 5, '바삭하고 맛있어요. 배달도 빨랐습니다.', '2026-10-03 10:00:00'),
(2, 2, 4, '피자가 조금 식어서 왔지만 맛은 좋았어요.', '2026-10-09 11:20:00'),
(3, 3, 3, NULL,                                       '2026-10-16 09:30:00'),
(4, 6, 5, '재주문 의사 100%입니다.',                  '2026-10-12 10:00:00'),
(5, 7, 2, '양이 적었어요.',                           '2026-10-19 14:00:00'),
(6, 8, 4, '무난하게 맛있어요.',                       '2026-10-21 10:30:00');

INSERT INTO ReviewHelpful (UserID, ReviewID, IsHelpful, CreatedAt) VALUES
(2, 1, TRUE,  '2026-10-04 09:00:00'),
(3, 1, TRUE,  '2026-10-04 10:00:00'),
(4, 1, FALSE, '2026-10-05 08:00:00'),
(2, 2, TRUE,  '2026-10-10 12:00:00'),
(3, 3, FALSE, '2026-10-17 12:00:00'),
(1, 4, TRUE,  '2026-10-13 09:00:00'),
(1, 5, FALSE, '2026-10-20 09:00:00'),
(3, 4, TRUE,  '2026-10-14 09:00:00');

SELECT 'Users' t, COUNT(*) c FROM Users
UNION ALL SELECT 'Addresses', COUNT(*) FROM Addresses
UNION ALL SELECT 'Stores', COUNT(*) FROM Stores
UNION ALL SELECT 'Favorites', COUNT(*) FROM Favorites
UNION ALL SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL SELECT 'Reviews', COUNT(*) FROM Reviews
UNION ALL SELECT 'ReviewHelpful', COUNT(*) FROM ReviewHelpful;
