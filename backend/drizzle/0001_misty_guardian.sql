CREATE TABLE `vouchers` (
	`id` int AUTO_INCREMENT NOT NULL,
	`code` varchar(50) NOT NULL,
	`discount_percent` int NOT NULL,
	`is_active` boolean NOT NULL DEFAULT true,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `vouchers_id` PRIMARY KEY(`id`),
	CONSTRAINT `vouchers_code_unique` UNIQUE(`code`)
);
--> statement-breakpoint
ALTER TABLE `orders` MODIFY COLUMN `status` enum('pending','processed','delivering','completed','cancelled') NOT NULL DEFAULT 'pending';--> statement-breakpoint
ALTER TABLE `orders` ADD `delivery_method` enum('pickup','delivery') DEFAULT 'pickup' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `payment_method` enum('transfer','cash') DEFAULT 'transfer' NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `address` text;--> statement-breakpoint
ALTER TABLE `orders` ADD `customer_phone` varchar(20) NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `voucher_code` varchar(50);--> statement-breakpoint
ALTER TABLE `orders` ADD `discount_amount` decimal(10,2) DEFAULT '0';