-- Run this only when upgrading from z_uwucafe v1.x. Back up your database first.
ALTER TABLE `z_uwucafe_business`
    ADD COLUMN IF NOT EXISTS `rating_total` INT NOT NULL DEFAULT 0 AFTER `reputation`,
    ADD COLUMN IF NOT EXISTS `rating_count` INT NOT NULL DEFAULT 0 AFTER `rating_total`;

ALTER TABLE `z_uwucafe_employees`
    ADD COLUMN IF NOT EXISTS `table_orders` INT NOT NULL DEFAULT 0 AFTER `orders_completed`,
    ADD COLUMN IF NOT EXISTS `customer_deliveries` INT NOT NULL DEFAULT 0 AFTER `table_orders`,
    ADD COLUMN IF NOT EXISTS `supply_deliveries` INT NOT NULL DEFAULT 0 AFTER `customer_deliveries`,
    ADD COLUMN IF NOT EXISTS `catering_completed` INT NOT NULL DEFAULT 0 AFTER `supply_deliveries`,
    ADD COLUMN IF NOT EXISTS `management_actions` INT NOT NULL DEFAULT 0 AFTER `cleaning_actions`,
    ADD COLUMN IF NOT EXISTS `cooking_xp` INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `drinks_xp` INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `service_xp` INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `delivery_xp` INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `management_xp` INT NOT NULL DEFAULT 0;

ALTER TABLE `z_uwucafe_orders`
    CHANGE COLUMN `source` `order_type` VARCHAR(30) NOT NULL DEFAULT 'terminal',
    MODIFY COLUMN `status` VARCHAR(30) NOT NULL DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS `customer_source` INT NULL AFTER `customer_name`,
    ADD COLUMN IF NOT EXISTS `payment_status` VARCHAR(20) NOT NULL DEFAULT 'paid' AFTER `payment_method`,
    ADD COLUMN IF NOT EXISTS `subtotal` INT NOT NULL DEFAULT 0 AFTER `payment_status`,
    ADD COLUMN IF NOT EXISTS `fee` INT NOT NULL DEFAULT 0 AFTER `subtotal`,
    ADD COLUMN IF NOT EXISTS `tip` INT NOT NULL DEFAULT 0 AFTER `fee`,
    ADD COLUMN IF NOT EXISTS `table_number` INT NULL AFTER `notes`,
    ADD COLUMN IF NOT EXISTS `delivery_x` DOUBLE NULL,
    ADD COLUMN IF NOT EXISTS `delivery_y` DOUBLE NULL,
    ADD COLUMN IF NOT EXISTS `delivery_z` DOUBLE NULL,
    ADD COLUMN IF NOT EXISTS `delivery_status` VARCHAR(30) NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS `delivery_identifier` VARCHAR(80) NULL,
    ADD COLUMN IF NOT EXISTS `fulfillment_json` LONGTEXT NULL,
    ADD COLUMN IF NOT EXISTS `quality_score` INT NULL,
    ADD COLUMN IF NOT EXISTS `rating` INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `paid_to_business` TINYINT(1) NOT NULL DEFAULT 0;

UPDATE `z_uwucafe_orders` SET `subtotal` = `total` WHERE `subtotal` = 0;

ALTER TABLE `z_uwucafe_deliveries`
    ADD COLUMN IF NOT EXISTS `delivery_type` VARCHAR(30) NOT NULL DEFAULT 'supply' AFTER `identifier`,
    ADD COLUMN IF NOT EXISTS `reference_id` INT NULL AFTER `delivery_type`,
    ADD COLUMN IF NOT EXISTS `damage_penalty` INT NOT NULL DEFAULT 0 AFTER `cost`;

-- Then run sql/install.sql. Its CREATE TABLE IF NOT EXISTS statements add every new v2 table.
