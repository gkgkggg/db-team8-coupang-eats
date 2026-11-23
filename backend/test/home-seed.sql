-- 홈 API 로컬 테스트용 가상 데이터. 공식 샘플 데이터(db/data.sql)가 나오면 그것을 사용한다.
-- 빈 db_team8에서 schema.sql 실행 직후 한 번만 실행한다.
USE db_team8;
SET NAMES utf8mb4;

INSERT INTO Users (UserID, UserName, UserPhone) VALUES
(1, '테스트사용자', '010-0000-0001'),
(2, '테스트사용자2', '010-0000-0002');

INSERT INTO Addresses (UserID, AddressLabel, PostalCode, AddressLine1, AddressLine2, IsDefault) VALUES
(1, '기숙사', '13120', '경기 성남시 수정구 성남대로 1342', '제1기숙사 101호', TRUE),
(1, '학교', '13120', '경기 성남시 수정구 성남대로 1342', 'AI관 2층', FALSE);

INSERT INTO Categories (CategoryID, CategoryName, CategoryImageURL, DisplayOrder) VALUES
(1, '한식', 'https://example.com/img/cat-korean.png', 1),
(2, '치킨', 'https://example.com/img/cat-chicken.png', 2),
(3, '피자', 'https://example.com/img/cat-pizza.png', 3),
(4, '분식', 'https://example.com/img/cat-snack.png', 4),
(5, '디저트', NULL, 5);

INSERT INTO Stores (StoreID, StoreName, StorePhone, StoreAddress, StoreImageURL,
                    MinimumOrderAmount, DeliveryFee, EstimatedDeliveryMinutes, IsOpen) VALUES
(1, '바삭치킨 가천점', '031-000-0001', '경기 성남시 수정구 성남대로 1', 'https://example.com/img/s1.png', 15000, 3000, 30, TRUE),
(2, '양념치킨집', '031-000-0002', '경기 성남시 수정구 성남대로 2', NULL, 18000, 0, 40, TRUE),
(3, '도우피자', '031-000-0003', '경기 성남시 수정구 성남대로 3', 'https://example.com/img/s3.png', 20000, 2000, 35, TRUE),
(4, '할매떡볶이', NULL, '경기 성남시 수정구 성남대로 4', NULL, 12000, 1500, 25, FALSE),
(5, '치킨앤피자', '031-000-0005', '경기 성남시 수정구 성남대로 5', NULL, 16000, 2500, NULL, TRUE),
(6, '100%_수제버거', NULL, '경기 성남시 수정구 성남대로 6', NULL, 10000, 1000, 20, TRUE);

INSERT INTO StoreCategories (StoreID, CategoryID) VALUES
(1, 2), (2, 2), (3, 3), (4, 4), (5, 2), (5, 3), (6, 1);

INSERT INTO Menus (StoreID, MenuName, CurrentPrice, MenuImageURL, IsAvailable) VALUES
(1, '후라이드치킨', 19000, 'https://example.com/img/m1.png', TRUE),
(1, '양념치킨', 21000, NULL, TRUE),
(1, '치즈볼', 5000, NULL, FALSE),
(2, '반반치킨', 20000, NULL, TRUE),
(3, '페퍼로니피자', 23000, NULL, TRUE),
(4, '떡볶이', 13000, NULL, TRUE);

INSERT INTO Orders (OrderID, UserID, StoreID, OrderStatus, DeliveryAddressText, DeliveryFee, DiscountAmount) VALUES
(101, 1, 1, 'completed', '경기 성남시 수정구 성남대로 1342', 3000, 0),
(102, 2, 1, 'completed', '경기 성남시 수정구 성남대로 1342', 3000, 0),
(103, 1, 2, 'completed', '경기 성남시 수정구 성남대로 1342', 0, 0),
(104, 1, 3, 'completed', '경기 성남시 수정구 성남대로 1342', 2000, 1000),
(105, 2, 3, 'completed', '경기 성남시 수정구 성남대로 1342', 2000, 0),
(106, 1, 5, 'preparing', '경기 성남시 수정구 성남대로 1342', 2500, 0);

INSERT INTO OrderItems (OrderID, MenuID, Quantity, UnitPriceAtOrder, MenuNameAtOrder) VALUES
(101, 1, 1, 19000, '후라이드치킨'),
(102, 2, 1, 21000, '양념치킨'),
(103, 4, 1, 20000, '반반치킨'),
(104, 5, 1, 23000, '페퍼로니피자'),
(105, 5, 2, 23000, '페퍼로니피자');

INSERT INTO Reviews (OrderID, Rating, Content) VALUES
(101, 5, '바삭해요'),
(102, 4, '맛있어요'),
(103, 3, '보통'),
(104, 5, '최고'),
(105, 5, '또 시킬게요');
