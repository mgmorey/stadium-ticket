CREATE SCHEMA IF NOT EXISTS `stadium-tickets`;
USE `stadium-tickets`;
CREATE TABLE IF NOT EXISTS `events` (
       `name` varchar(32) NOT NULL,
       `sold` int NOT NULL,
       `total` int NOT NULL,
       PRIMARY KEY (`name`) );
DELETE FROM `events`;
INSERT INTO `events` (`name`, `sold`, `total`) VALUES ('SoldOut', 0, 1000);
INSERT INTO `events` (`name`, `sold`, `total`) VALUES ('The Beatles', 0, 1000);
INSERT INTO `events` (`name`, `sold`, `total`) VALUES ('The Cure', 0, 1000);
INSERT INTO `events` (`name`, `sold`, `total`) VALUES ('The Doors', 0, 1000);
INSERT INTO `events` (`name`, `sold`, `total`) VALUES ('The Who', 0, 1000);
