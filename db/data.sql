-- schema.sql로 만든 빈 개발용 DB에서 한 번 실행한다. 모든 이름과 주소는 가상이다.
USE `db_team8`;
SET NAMES utf8mb4;

-- 외부 요청 없이 표시할 수 있는 24×24 PNG. 일부 행은 이미지 없음(NULL)도 확인한다.
SET @sample_image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAH0lEQVR4nGPgSFtMFcQwatCoQaMGjRo0atCoQQNvEAAIM2ZfPmSfZQAAAABJRU5ErkJggg==';

START TRANSACTION;

INSERT INTO `Users` (`UserID`, `UserName`, `UserPhone`, `CreatedAt`) VALUES
    (1, '테스트 사용자 A', '010-0000-0001', '2026-11-01 09:00:00'),
    (2, '테스트 사용자 B', '010-0000-0002', '2026-11-01 10:00:00'),
    (3, '테스트 사용자 C', NULL, '2026-11-01 11:00:00');

INSERT INTO `Addresses` (`AddressID`, `UserID`, `AddressLabel`, `PostalCode`, `AddressLine1`,
    `AddressLine2`, `IsDefault`, `CreatedAt`) VALUES
    (1, 1, '집', '01234', '테스트시 연습로 1', '101호', TRUE, '2026-11-01 09:05:00'),
    (2, 1, '회사', '01235', '테스트시 연습로 2', NULL, FALSE, '2026-11-01 09:10:00'),
    (3, 2, '집', NULL, '테스트시 연습로 3', NULL, FALSE, '2026-11-01 10:05:00');

INSERT INTO `Categories` (`CategoryID`, `CategoryName`, `CategoryImageURL`, `DisplayOrder`) VALUES
    (1, '한식', @sample_image, 20),
    (2, '치킨', @sample_image, 10),
    (3, '분식', NULL, 30);

INSERT INTO `Stores` (`StoreID`, `StoreName`, `StorePhone`, `StoreAddress`, `StoreImageURL`,
    `MinimumOrderAmount`, `DeliveryFee`, `EstimatedDeliveryMinutes`, `IsOpen`) VALUES
    (1, '테스트 치킨집', '02-000-0001', '테스트시 가게로 1', @sample_image, 12000, 2500, 30, TRUE),
    (2, '테스트 한식당', '02-000-0002', '테스트시 가게로 2', NULL, 14000, 3000, 40, FALSE),
    (3, '테스트 분식집', NULL, '테스트시 가게로 3', @sample_image, 8000, 0, NULL, TRUE);

-- 1번 가게는 한식과 치킨에 모두 속한다.
INSERT INTO `StoreCategories` (`StoreID`, `CategoryID`) VALUES
    (1, 1), (1, 2), (2, 1), (3, 3);

INSERT INTO `Menus` (`MenuID`, `StoreID`, `MenuName`, `CurrentPrice`, `MenuImageURL`, `IsAvailable`) VALUES
    (1, 1, '바삭 치킨', 18000, @sample_image, TRUE),
    (2, 1, '매운 치킨', 19000, NULL, FALSE),
    (3, 2, '제육 덮밥', 14000, NULL, TRUE),
    (4, 3, '떡볶이', 8000, @sample_image, TRUE);

-- Postman에서 1번 사용자가 3번 가게를 새로 추가할 수 있게 이 조합은 비워 둔다.
INSERT INTO `Favorites` (`UserID`, `StoreID`, `CreatedAt`) VALUES
    (1, 1, '2026-11-02 10:00:00'),
    (2, 3, '2026-11-02 11:00:00');

INSERT INTO `Orders` (`OrderID`, `UserID`, `StoreID`, `OrderedAt`, `OrderStatus`,
    `DeliveryAddressText`, `DeliveryFee`, `DiscountAmount`) VALUES
    (101, 1, 1, '2026-11-10 18:30:00', 'completed', '테스트시 이전로 9 101호', 2000, 1000),
    (102, 2, 1, '2026-11-11 18:30:00', 'completed', '테스트시 연습로 3', 2500, 0),
    (103, 1, 3, '2026-11-23 18:00:00', 'preparing', '테스트시 연습로 1 101호', 0, 0),
    (104, 1, 1, '2026-11-23 18:05:00', 'delivering', '테스트시 연습로 1 101호', 2500, 1000),
    (105, 1, 3, '2026-11-23 17:00:00', 'cancelled', '테스트시 연습로 2', 0, 0),
    (106, 2, 3, '2026-11-22 18:00:00', 'completed', '테스트시 연습로 3', 0, 0);

-- 101번 주문에는 현재와 다른 메뉴명·단가·주소·배달비를 보관한다.
INSERT INTO `OrderItems` (`OrderID`, `MenuID`, `Quantity`, `UnitPriceAtOrder`, `MenuNameAtOrder`) VALUES
    (101, 1, 2, 17000, '후라이드 치킨'),
    (101, 2, 1, 18500, '매운 치킨'),
    (102, 1, 1, 18000, '바삭 치킨'),
    (103, 4, 2, 8000, '떡볶이'),
    (104, 1, 1, 18000, '바삭 치킨'),
    (105, 4, 1, 8000, '떡볶이'),
    (106, 4, 1, 8000, '떡볶이');

-- 1번 가게의 리뷰는 2건이다. 3번 가게는 완료 주문이 있지만 리뷰는 없다.
INSERT INTO `Reviews` (`ReviewID`, `OrderID`, `Rating`, `Content`, `CreatedAt`) VALUES
    (1, 101, 5, '바삭하고 따뜻했어요.', '2026-11-10 20:00:00'),
    (2, 102, 4, NULL, '2026-11-11 20:00:00');

INSERT INTO `ReviewHelpful` (`UserID`, `ReviewID`, `IsHelpful`, `CreatedAt`) VALUES
    (2, 1, TRUE, '2026-11-12 09:00:00'),
    (3, 1, FALSE, '2026-11-12 09:30:00');

COMMIT;
SET @sample_image = NULL;
