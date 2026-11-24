INSERT IGNORE INTO `jobs` (`name`, `label`) VALUES ('uwucafe', 'UwU Cat Cafe');

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('uwucafe', 0, 'trainee', 'Trainee', 0, '{}', '{}'),
('uwucafe', 1, 'employee', 'Employee', 0, '{}', '{}'),
('uwucafe', 2, 'senior', 'Senior Employee', 0, '{}', '{}'),
('uwucafe', 3, 'supervisor', 'Supervisor', 0, '{}', '{}'),
('uwucafe', 4, 'manager', 'Manager', 0, '{}', '{}'),
('uwucafe', 5, 'owner', 'Owner', 0, '{}', '{}')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `label` = VALUES(`label`), `salary` = VALUES(`salary`);

CREATE TABLE IF NOT EXISTS `z_uwucafe_business` (
    `id` INT NOT NULL,
    `balance` INT NOT NULL DEFAULT 0,
    `cleanliness` INT NOT NULL DEFAULT 100,
    `reputation` INT NOT NULL DEFAULT 0,
    `rating_total` INT NOT NULL DEFAULT 0,
    `rating_count` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT IGNORE INTO `z_uwucafe_business` (`id`) VALUES (1);

CREATE TABLE IF NOT EXISTS `z_uwucafe_employees` (
    `identifier` VARCHAR(80) NOT NULL,
    `xp` INT NOT NULL DEFAULT 0,
    `total_minutes` INT NOT NULL DEFAULT 0,
    `crafts` INT NOT NULL DEFAULT 0,
    `orders_completed` INT NOT NULL DEFAULT 0,
    `table_orders` INT NOT NULL DEFAULT 0,
    `customer_deliveries` INT NOT NULL DEFAULT 0,
    `supply_deliveries` INT NOT NULL DEFAULT 0,
    `catering_completed` INT NOT NULL DEFAULT 0,
    `cleaning_actions` INT NOT NULL DEFAULT 0,
    `management_actions` INT NOT NULL DEFAULT 0,
    `cooking_xp` INT NOT NULL DEFAULT 0,
    `drinks_xp` INT NOT NULL DEFAULT 0,
    `service_xp` INT NOT NULL DEFAULT 0,
    `delivery_xp` INT NOT NULL DEFAULT 0,
    `management_xp` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_orders` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `customer_identifier` VARCHAR(80) NOT NULL,
    `customer_name` VARCHAR(100) NOT NULL,
    `customer_source` INT NULL,
    `employee_identifier` VARCHAR(80) NULL,
    `order_type` VARCHAR(30) NOT NULL DEFAULT 'terminal',
    `status` VARCHAR(30) NOT NULL DEFAULT 'pending',
    `payment_method` VARCHAR(20) NOT NULL DEFAULT 'bank',
    `payment_status` VARCHAR(20) NOT NULL DEFAULT 'paid',
    `subtotal` INT NOT NULL DEFAULT 0,
    `fee` INT NOT NULL DEFAULT 0,
    `tip` INT NOT NULL DEFAULT 0,
    `total` INT NOT NULL DEFAULT 0,
    `notes` VARCHAR(250) NULL,
    `table_number` INT NULL,
    `delivery_x` DOUBLE NULL,
    `delivery_y` DOUBLE NULL,
    `delivery_z` DOUBLE NULL,
    `delivery_status` VARCHAR(30) NOT NULL DEFAULT 'none',
    `delivery_identifier` VARCHAR(80) NULL,
    `fulfillment_json` LONGTEXT NULL,
    `quality_score` INT NULL,
    `rating` INT NOT NULL DEFAULT 0,
    `paid_to_business` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_orders_status` (`status`),
    KEY `idx_uwu_orders_customer` (`customer_identifier`),
    KEY `idx_uwu_orders_type_delivery` (`order_type`, `delivery_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_order_items` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `order_id` INT NOT NULL,
    `item_name` VARCHAR(80) NOT NULL,
    `item_label` VARCHAR(100) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 1,
    `unit_price` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_order_items_order` (`order_id`),
    CONSTRAINT `fk_uwu_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `z_uwucafe_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_order_events` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `order_id` INT NOT NULL,
    `event_type` VARCHAR(40) NOT NULL,
    `actor_identifier` VARCHAR(80) NULL,
    `details` LONGTEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_order_events_order` (`order_id`),
    CONSTRAINT `fk_uwu_order_events_order` FOREIGN KEY (`order_id`) REFERENCES `z_uwucafe_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_transactions` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `amount` INT NOT NULL,
    `reason` VARCHAR(160) NOT NULL,
    `actor_identifier` VARCHAR(80) NULL,
    `metadata` LONGTEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_transactions_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_deliveries` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(80) NOT NULL,
    `delivery_type` VARCHAR(30) NOT NULL,
    `reference_id` INT NULL,
    `pack_id` VARCHAR(50) NULL,
    `token` VARCHAR(190) NOT NULL,
    `status` VARCHAR(30) NOT NULL DEFAULT 'started',
    `cost` INT NOT NULL DEFAULT 0,
    `damage_penalty` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_uwu_delivery_token` (`token`),
    KEY `idx_uwu_deliveries_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_equipment` (
    `station_id` VARCHAR(50) NOT NULL,
    `equipment_key` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `level` INT NOT NULL DEFAULT 1,
    `condition_value` INT NOT NULL DEFAULT 100,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`station_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_promotions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(80) NOT NULL,
    `scope` VARCHAR(20) NOT NULL DEFAULT 'all',
    `target` VARCHAR(80) NULL,
    `discount_percent` INT NOT NULL,
    `starts_at` DATETIME NOT NULL,
    `ends_at` DATETIME NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(80) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_promotions_active` (`active`, `ends_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_catering` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `template_key` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `destination_id` VARCHAR(50) NOT NULL,
    `destination_label` VARCHAR(100) NOT NULL,
    `items_json` LONGTEXT NOT NULL,
    `reward` INT NOT NULL,
    `minimum_reputation` INT NOT NULL DEFAULT 0,
    `status` VARCHAR(30) NOT NULL DEFAULT 'available',
    `accepted_by` VARCHAR(80) NULL,
    `token` VARCHAR(190) NULL,
    `expires_at` DATETIME NOT NULL,
    `accepted_at` DATETIME NULL,
    `due_at` DATETIME NULL,
    `completed_at` DATETIME NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_catering_status` (`status`, `expires_at`),
    KEY `idx_uwu_catering_employee` (`accepted_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_upgrades` (
    `upgrade_key` VARCHAR(50) NOT NULL,
    `level` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`upgrade_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_staff_calls` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `table_number` INT NOT NULL,
    `customer_identifier` VARCHAR(80) NULL,
    `customer_name` VARCHAR(100) NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'open',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `resolved_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_staff_calls_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_refunds` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(80) NOT NULL,
    `amount` INT NOT NULL,
    `payment_method` VARCHAR(20) NOT NULL DEFAULT 'bank',
    `reason` VARCHAR(160) NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `paid_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_refunds_identifier` (`identifier`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `z_uwucafe_duty_sessions` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(80) NOT NULL,
    `started_at` DATETIME NOT NULL,
    `ended_at` DATETIME NOT NULL,
    `minutes` INT NOT NULL DEFAULT 0,
    `payroll_amount` INT NOT NULL DEFAULT 0,
    `payroll_status` VARCHAR(30) NOT NULL,
    `end_reason` VARCHAR(80) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_uwu_duty_identifier` (`identifier`, `started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
