-- 데이터베이스 8조: 홈 / 마이이츠 / 주문내역
-- MySQL 8.0.16 이상. MySQL 8.4 권장.
-- 11개 테이블, 58개 컬럼. 샘플 데이터는 data.sql에서 별도로 입력합니다.
-- 기존 테이블은 삭제하지 않으며, 이미 있는 테이블의 구조도 변경하지 않습니다.

CREATE DATABASE IF NOT EXISTS `db_team8`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `db_team8`;
SET NAMES utf8mb4;

-- 사용자
CREATE TABLE IF NOT EXISTS `Users` (
    `UserID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `UserName` VARCHAR(50) NOT NULL,
    `UserPhone` VARCHAR(20) NULL,
    `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 사용자 주소: 일반 주소는 여러 개, 기본 주소는 사용자별 최대 한 개
CREATE TABLE IF NOT EXISTS `Addresses` (
    `AddressID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `UserID` BIGINT UNSIGNED NOT NULL,
    `AddressLabel` VARCHAR(20) NOT NULL,
    `PostalCode` CHAR(5) NULL,
    `AddressLine1` VARCHAR(200) NOT NULL,
    `AddressLine2` VARCHAR(100) NULL,
    `IsDefault` BOOLEAN NOT NULL DEFAULT FALSE,
    `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`AddressID`),
    KEY `idx_addresses_user_default` (`UserID`, `IsDefault`),
    UNIQUE KEY `uq_addresses_one_default`
        ((CASE WHEN `IsDefault` = TRUE THEN `UserID` ELSE NULL END)),
    CONSTRAINT `ck_addresses_is_default` CHECK (`IsDefault` IN (0, 1)),
    CONSTRAINT `fk_addresses_user` FOREIGN KEY (`UserID`)
        REFERENCES `Users` (`UserID`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 음식 카테고리
CREATE TABLE IF NOT EXISTS `Categories` (
    `CategoryID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `CategoryName` VARCHAR(30) NOT NULL,
    `CategoryImageURL` VARCHAR(500) NULL,
    `DisplayOrder` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`CategoryID`),
    UNIQUE KEY `uq_categories_name` (`CategoryName`),
    KEY `idx_categories_display_order` (`DisplayOrder`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 가게: 금액 단위는 원(KRW)
CREATE TABLE IF NOT EXISTS `Stores` (
    `StoreID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `StoreName` VARCHAR(100) NOT NULL,
    `StorePhone` VARCHAR(20) NULL,
    `StoreAddress` VARCHAR(255) NOT NULL,
    `StoreImageURL` VARCHAR(500) NULL,
    `MinimumOrderAmount` DECIMAL(10,0) NOT NULL,
    `DeliveryFee` DECIMAL(10,0) NOT NULL,
    `EstimatedDeliveryMinutes` SMALLINT UNSIGNED NULL,
    `IsOpen` BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (`StoreID`),
    KEY `idx_stores_name` (`StoreName`),
    KEY `idx_stores_open_delivery_fee` (`IsOpen`, `DeliveryFee`),
    CONSTRAINT `ck_stores_minimum_order` CHECK (`MinimumOrderAmount` >= 0),
    CONSTRAINT `ck_stores_delivery_fee` CHECK (`DeliveryFee` >= 0),
    CONSTRAINT `ck_stores_is_open` CHECK (`IsOpen` IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 가게와 음식 카테고리의 다대다 관계
CREATE TABLE IF NOT EXISTS `StoreCategories` (
    `StoreID` BIGINT UNSIGNED NOT NULL,
    `CategoryID` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`StoreID`, `CategoryID`),
    KEY `idx_store_categories_category` (`CategoryID`),
    CONSTRAINT `fk_store_categories_store` FOREIGN KEY (`StoreID`)
        REFERENCES `Stores` (`StoreID`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_store_categories_category` FOREIGN KEY (`CategoryID`)
        REFERENCES `Categories` (`CategoryID`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 가게 메뉴의 현재 정보
CREATE TABLE IF NOT EXISTS `Menus` (
    `MenuID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `StoreID` BIGINT UNSIGNED NOT NULL,
    `MenuName` VARCHAR(100) NOT NULL,
    `CurrentPrice` DECIMAL(10,0) NOT NULL,
    `MenuImageURL` VARCHAR(500) NULL,
    `IsAvailable` BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (`MenuID`),
    KEY `idx_menus_store_available` (`StoreID`, `IsAvailable`),
    CONSTRAINT `ck_menus_current_price` CHECK (`CurrentPrice` >= 0),
    CONSTRAINT `ck_menus_is_available` CHECK (`IsAvailable` IN (0, 1)),
    CONSTRAINT `fk_menus_store` FOREIGN KEY (`StoreID`)
        REFERENCES `Stores` (`StoreID`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 즐겨찾기: 같은 사용자·가게를 중복 등록하지 않음
CREATE TABLE IF NOT EXISTS `Favorites` (
    `UserID` BIGINT UNSIGNED NOT NULL,
    `StoreID` BIGINT UNSIGNED NOT NULL,
    `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`UserID`, `StoreID`),
    KEY `idx_favorites_store` (`StoreID`),
    CONSTRAINT `fk_favorites_user` FOREIGN KEY (`UserID`)
        REFERENCES `Users` (`UserID`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_favorites_store` FOREIGN KEY (`StoreID`)
        REFERENCES `Stores` (`StoreID`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 주문: 배송 주소·배달비·할인액은 주문 당시 값을 보관
CREATE TABLE IF NOT EXISTS `Orders` (
    `OrderID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `UserID` BIGINT UNSIGNED NOT NULL,
    `StoreID` BIGINT UNSIGNED NOT NULL,
    `OrderedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `OrderStatus` VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    `DeliveryAddressText` VARCHAR(300) NOT NULL,
    `DeliveryFee` DECIMAL(10,0) NOT NULL,
    `DiscountAmount` DECIMAL(10,0) NOT NULL DEFAULT 0,
    PRIMARY KEY (`OrderID`),
    KEY `idx_orders_user_status_time` (`UserID`, `OrderStatus`, `OrderedAt`),
    KEY `idx_orders_store` (`StoreID`),
    CONSTRAINT `ck_orders_status` CHECK
        (`OrderStatus` IN ('preparing', 'delivering', 'completed', 'cancelled')),
    CONSTRAINT `ck_orders_delivery_fee` CHECK (`DeliveryFee` >= 0),
    CONSTRAINT `ck_orders_discount` CHECK (`DiscountAmount` >= 0),
    CONSTRAINT `fk_orders_user` FOREIGN KEY (`UserID`)
        REFERENCES `Users` (`UserID`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_orders_store` FOREIGN KEY (`StoreID`)
        REFERENCES `Stores` (`StoreID`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 주문 항목: 같은 메뉴는 수량으로 합산, 주문 당시 메뉴명·단가 보관
CREATE TABLE IF NOT EXISTS `OrderItems` (
    `OrderID` BIGINT UNSIGNED NOT NULL,
    `MenuID` BIGINT UNSIGNED NOT NULL,
    `Quantity` INT UNSIGNED NOT NULL,
    `UnitPriceAtOrder` DECIMAL(10,0) NOT NULL,
    `MenuNameAtOrder` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`OrderID`, `MenuID`),
    KEY `idx_order_items_menu` (`MenuID`),
    CONSTRAINT `ck_order_items_quantity` CHECK (`Quantity` >= 1),
    CONSTRAINT `ck_order_items_unit_price` CHECK (`UnitPriceAtOrder` >= 0),
    CONSTRAINT `fk_order_items_order` FOREIGN KEY (`OrderID`)
        REFERENCES `Orders` (`OrderID`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_order_items_menu` FOREIGN KEY (`MenuID`)
        REFERENCES `Menus` (`MenuID`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 주문 리뷰: 주문당 최대 한 개
CREATE TABLE IF NOT EXISTS `Reviews` (
    `ReviewID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `OrderID` BIGINT UNSIGNED NOT NULL,
    `Rating` TINYINT UNSIGNED NOT NULL,
    `Content` TEXT NULL,
    `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`ReviewID`),
    UNIQUE KEY `uq_reviews_order` (`OrderID`),
    CONSTRAINT `ck_reviews_rating` CHECK (`Rating` BETWEEN 1 AND 5),
    CONSTRAINT `fk_reviews_order` FOREIGN KEY (`OrderID`)
        REFERENCES `Orders` (`OrderID`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 리뷰 반응: TRUE=도움이 돼요, FALSE=도움이 안 돼요, 행 삭제=취소
CREATE TABLE IF NOT EXISTS `ReviewHelpful` (
    `UserID` BIGINT UNSIGNED NOT NULL,
    `ReviewID` BIGINT UNSIGNED NOT NULL,
    `IsHelpful` BOOLEAN NOT NULL,
    `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`UserID`, `ReviewID`),
    KEY `idx_review_helpful_review_flag` (`ReviewID`, `IsHelpful`),
    CONSTRAINT `ck_review_helpful_flag` CHECK (`IsHelpful` IN (0, 1)),
    CONSTRAINT `fk_review_helpful_user` FOREIGN KEY (`UserID`)
        REFERENCES `Users` (`UserID`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_review_helpful_review` FOREIGN KEY (`ReviewID`)
        REFERENCES `Reviews` (`ReviewID`) ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SHOW TABLES;
