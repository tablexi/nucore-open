CREATE TABLE `account_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `user_role` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL,
  `created_by` int(11) NOT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_accounts` (`account_id`),
  CONSTRAINT `fk_accounts` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL,
  `account_number` varchar(50) NOT NULL,
  `description` varchar(50) NOT NULL,
  `expires_at` datetime NOT NULL,
  `name_on_card` varchar(200) DEFAULT NULL,
  `expiration_month` int(11) DEFAULT NULL,
  `expiration_year` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `created_by` int(11) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `suspended_at` datetime DEFAULT NULL,
  `remittance_information` text,
  `facility_id` int(11) DEFAULT NULL,
  `affiliate_id` int(11) DEFAULT NULL,
  `affiliate_other` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_accounts_on_affiliate_id` (`affiliate_id`),
  KEY `fk_account_facility_id` (`facility_id`),
  CONSTRAINT `fk_account_facility_id` FOREIGN KEY (`facility_id`) REFERENCES `facilities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `affiliates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `budgeted_chart_strings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fund` varchar(20) NOT NULL,
  `dept` varchar(20) NOT NULL,
  `project` varchar(20) DEFAULT NULL,
  `activity` varchar(20) DEFAULT NULL,
  `account` varchar(20) DEFAULT NULL,
  `starts_at` datetime NOT NULL,
  `expires_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `bundle_products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bundle_product_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_bundle_prod_prod` (`bundle_product_id`),
  KEY `fk_bundle_prod_bundle` (`product_id`),
  CONSTRAINT `fk_bundle_prod_prod` FOREIGN KEY (`bundle_product_id`) REFERENCES `products` (`id`),
  CONSTRAINT `fk_bundle_prod_bundle` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `external_service_passers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `external_service_id` int(11) DEFAULT NULL,
  `passer_id` int(11) DEFAULT NULL,
  `passer_type` varchar(255) DEFAULT NULL,
  `active` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `external_service_receivers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `external_service_id` int(11) DEFAULT NULL,
  `receiver_id` int(11) DEFAULT NULL,
  `receiver_type` varchar(255) DEFAULT NULL,
  `response_data` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `external_services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facilities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL,
  `abbreviation` varchar(50) NOT NULL,
  `url_name` varchar(50) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `description` text,
  `accepts_cc` tinyint(1) DEFAULT '1',
  `accepts_po` tinyint(1) DEFAULT '1',
  `short_description` text NOT NULL,
  `address` text,
  `phone_number` varchar(255) DEFAULT NULL,
  `fax_number` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `journal_mask` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_c008532` (`abbreviation`),
  UNIQUE KEY `sys_c008531` (`name`),
  UNIQUE KEY `sys_c008533` (`url_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facility_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `facility_id` int(11) NOT NULL,
  `account_number` varchar(50) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `revenue_account` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_facilities` (`facility_id`),
  CONSTRAINT `fk_facilities` FOREIGN KEY (`facility_id`) REFERENCES `facilities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `file_uploads` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_detail_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `name` varchar(200) NOT NULL,
  `file_type` varchar(50) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `file_file_name` varchar(255) DEFAULT NULL,
  `file_content_type` varchar(255) DEFAULT NULL,
  `file_file_size` int(11) DEFAULT NULL,
  `file_updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_files_od` (`order_detail_id`),
  KEY `fk_files_product` (`product_id`),
  CONSTRAINT `fk_files_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  CONSTRAINT `fk_files_od` FOREIGN KEY (`order_detail_id`) REFERENCES `order_details` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `instrument_statuses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `instrument_id` int(11) NOT NULL,
  `is_on` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_int_stats_product` (`instrument_id`),
  CONSTRAINT `fk_int_stats_product` FOREIGN KEY (`instrument_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `journal_rows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `journal_id` int(11) NOT NULL,
  `order_detail_id` int(11) DEFAULT NULL,
  `amount` decimal(9,2) NOT NULL,
  `description` varchar(200) DEFAULT NULL,
  `reference` varchar(50) DEFAULT NULL,
  `fund` varchar(3) NOT NULL,
  `dept` varchar(7) NOT NULL,
  `project` varchar(8) DEFAULT NULL,
  `activity` varchar(2) DEFAULT NULL,
  `program` varchar(4) DEFAULT NULL,
  `account` varchar(5) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `journals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `facility_id` int(11) NOT NULL,
  `reference` varchar(50) DEFAULT NULL,
  `description` varchar(200) DEFAULT NULL,
  `is_successful` tinyint(1) DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `file_file_name` varchar(255) DEFAULT NULL,
  `file_content_type` varchar(255) DEFAULT NULL,
  `file_file_size` int(11) DEFAULT NULL,
  `file_updated_at` datetime DEFAULT NULL,
  `journal_date` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `nucs_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` varchar(16) NOT NULL,
  `auxiliary` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_nucs_accounts_on_value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `nucs_chart_field1s` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` varchar(16) NOT NULL,
  `auxiliary` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `i_nucs_chart_field1s_value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `nucs_departments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` varchar(16) NOT NULL,
  `auxiliary` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `i_nucs_departments_value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `nucs_funds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` varchar(8) NOT NULL,
  `auxiliary` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_nucs_funds_on_value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `nucs_gl066s` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `budget_period` varchar(8) NOT NULL,
  `fund` varchar(8) NOT NULL,
  `department` varchar(16) NOT NULL,
  `project` varchar(16) NOT NULL,
  `activity` varchar(16) NOT NULL,
  `account` varchar(16) NOT NULL,
  `starts_at` datetime DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_nucs_gl066s_on_account` (`account`),
  KEY `index_nucs_gl066s_on_activity` (`activity`),
  KEY `i_nucs_gl066s_department` (`department`),
  KEY `index_nucs_gl066s_on_fund` (`fund`),
  KEY `index_nucs_gl066s_on_project` (`project`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `nucs_grants_budget_trees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account` varchar(16) NOT NULL,
  `account_desc` varchar(32) NOT NULL,
  `roll_up_node` varchar(32) NOT NULL,
  `roll_up_node_desc` varchar(32) NOT NULL,
  `parent_node` varchar(32) NOT NULL,
  `parent_node_desc` varchar(32) NOT NULL,
  `account_effective_at` datetime NOT NULL,
  `tree` varchar(32) NOT NULL,
  `tree_effective_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `i_nuc_gra_bud_tre_acc` (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `nucs_programs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` varchar(8) NOT NULL,
  `auxiliary` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_nucs_programs_on_value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `nucs_project_activities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `project` varchar(16) NOT NULL,
  `activity` varchar(16) NOT NULL,
  `auxiliary` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `i_nuc_pro_act_act` (`activity`),
  KEY `i_nuc_pro_act_pro` (`project`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `order_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price_policy_id` int(11) DEFAULT NULL,
  `actual_cost` decimal(10,2) DEFAULT NULL,
  `actual_subsidy` decimal(10,2) DEFAULT NULL,
  `assigned_user_id` int(11) DEFAULT NULL,
  `estimated_cost` decimal(10,2) DEFAULT NULL,
  `estimated_subsidy` decimal(10,2) DEFAULT NULL,
  `account_id` int(11) DEFAULT NULL,
  `dispute_at` datetime DEFAULT NULL,
  `dispute_reason` varchar(200) DEFAULT NULL,
  `dispute_resolved_at` datetime DEFAULT NULL,
  `dispute_resolved_reason` varchar(200) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `order_status_id` int(11) NOT NULL,
  `state` varchar(50) DEFAULT NULL,
  `response_set_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `bundle_product_id` int(11) DEFAULT NULL,
  `note` varchar(25) DEFAULT NULL,
  `fulfilled_at` datetime DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `statement_id` int(11) DEFAULT NULL,
  `journal_id` int(11) DEFAULT NULL,
  `reconciled_note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_od_accounts` (`account_id`),
  KEY `fk_bundle_prod_id` (`bundle_product_id`),
  KEY `sys_c009172` (`order_id`),
  KEY `sys_c009175` (`price_policy_id`),
  KEY `sys_c009173` (`product_id`),
  CONSTRAINT `sys_c009173` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  CONSTRAINT `fk_bundle_prod_id` FOREIGN KEY (`bundle_product_id`) REFERENCES `products` (`id`),
  CONSTRAINT `fk_od_accounts` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT `sys_c009172` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  CONSTRAINT `sys_c009175` FOREIGN KEY (`price_policy_id`) REFERENCES `price_policies` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `order_statuses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `facility_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `lft` int(11) DEFAULT NULL,
  `rgt` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_c008542` (`facility_id`,`parent_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `ordered_at` datetime DEFAULT NULL,
  `facility_id` int(11) DEFAULT NULL,
  `state` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sys_c008808` (`account_id`),
  KEY `orders_facility_id_fk` (`facility_id`),
  CONSTRAINT `orders_facility_id_fk` FOREIGN KEY (`facility_id`) REFERENCES `facilities` (`id`),
  CONSTRAINT `sys_c008808` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `price_group_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL,
  `price_group_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `account_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sys_c008583` (`price_group_id`),
  CONSTRAINT `sys_c008583` FOREIGN KEY (`price_group_id`) REFERENCES `price_groups` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `price_group_products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `price_group_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `reservation_window` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `i_pri_gro_pro_pri_gro_id` (`price_group_id`),
  KEY `i_pri_gro_pro_pro_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `price_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `facility_id` int(11) DEFAULT NULL,
  `name` varchar(50) NOT NULL,
  `display_order` int(11) NOT NULL,
  `is_internal` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_c008577` (`facility_id`,`name`),
  CONSTRAINT `sys_c008578` FOREIGN KEY (`facility_id`) REFERENCES `facilities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `price_policies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL,
  `instrument_id` int(11) DEFAULT NULL,
  `service_id` int(11) DEFAULT NULL,
  `item_id` int(11) DEFAULT NULL,
  `price_group_id` int(11) NOT NULL,
  `start_date` datetime NOT NULL,
  `unit_cost` decimal(10,2) DEFAULT NULL,
  `unit_subsidy` decimal(10,2) DEFAULT NULL,
  `usage_rate` decimal(10,2) DEFAULT NULL,
  `usage_mins` int(11) DEFAULT NULL,
  `reservation_rate` decimal(10,2) DEFAULT NULL,
  `reservation_mins` int(11) DEFAULT NULL,
  `overage_rate` decimal(10,2) DEFAULT NULL,
  `overage_mins` int(11) DEFAULT NULL,
  `minimum_cost` decimal(10,2) DEFAULT NULL,
  `cancellation_cost` decimal(10,2) DEFAULT NULL,
  `usage_subsidy` decimal(10,2) DEFAULT NULL,
  `reservation_subsidy` decimal(10,2) DEFAULT NULL,
  `overage_subsidy` decimal(10,2) DEFAULT NULL,
  `expire_date` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sys_c008589` (`price_group_id`),
  CONSTRAINT `sys_c008589` FOREIGN KEY (`price_group_id`) REFERENCES `price_groups` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `product_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `approved_by` int(11) NOT NULL,
  `approved_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_products` (`product_id`),
  CONSTRAINT `fk_products` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL,
  `facility_id` int(11) NOT NULL,
  `name` varchar(200) NOT NULL,
  `url_name` varchar(50) NOT NULL,
  `description` text,
  `requires_approval` tinyint(1) NOT NULL,
  `initial_order_status_id` int(11) DEFAULT NULL,
  `is_archived` tinyint(1) NOT NULL,
  `is_hidden` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `relay_ip` varchar(15) DEFAULT NULL,
  `relay_port` int(11) DEFAULT NULL,
  `auto_logout` tinyint(1) DEFAULT NULL,
  `min_reserve_mins` int(11) DEFAULT NULL,
  `max_reserve_mins` int(11) DEFAULT NULL,
  `min_cancel_hours` int(11) DEFAULT NULL,
  `facility_account_id` int(11) DEFAULT NULL,
  `relay_username` varchar(50) DEFAULT NULL,
  `relay_password` varchar(50) DEFAULT NULL,
  `account` varchar(5) DEFAULT NULL,
  `relay_type` varchar(50) DEFAULT NULL,
  `show_details` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_c008555` (`relay_ip`,`relay_port`),
  KEY `fk_facility_accounts` (`facility_account_id`),
  KEY `sys_c008556` (`facility_id`),
  CONSTRAINT `fk_facility_accounts` FOREIGN KEY (`facility_account_id`) REFERENCES `facility_accounts` (`id`),
  CONSTRAINT `sys_c008556` FOREIGN KEY (`facility_id`) REFERENCES `facilities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `reservations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_detail_id` int(11) DEFAULT NULL,
  `instrument_id` int(11) NOT NULL,
  `reserve_start_at` datetime NOT NULL,
  `reserve_end_at` datetime NOT NULL,
  `actual_start_at` datetime DEFAULT NULL,
  `actual_end_at` datetime DEFAULT NULL,
  `canceled_at` datetime DEFAULT NULL,
  `canceled_by` int(11) DEFAULT NULL,
  `canceled_reason` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `reservations_instrument_id_fk` (`instrument_id`),
  KEY `res_ord_det_id_fk` (`order_detail_id`),
  CONSTRAINT `reservations_instrument_id_fk` FOREIGN KEY (`instrument_id`) REFERENCES `products` (`id`),
  CONSTRAINT `res_ord_det_id_fk` FOREIGN KEY (`order_detail_id`) REFERENCES `order_details` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schedule_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `instrument_id` int(11) NOT NULL,
  `discount_percent` decimal(10,2) NOT NULL DEFAULT '0.00',
  `start_hour` int(11) NOT NULL,
  `start_min` int(11) NOT NULL,
  `end_hour` int(11) NOT NULL,
  `end_min` int(11) NOT NULL,
  `duration_mins` int(11) NOT NULL,
  `on_sun` tinyint(1) NOT NULL,
  `on_mon` tinyint(1) NOT NULL,
  `on_tue` tinyint(1) NOT NULL,
  `on_wed` tinyint(1) NOT NULL,
  `on_thu` tinyint(1) NOT NULL,
  `on_fri` tinyint(1) NOT NULL,
  `on_sat` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sys_c008573` (`instrument_id`),
  CONSTRAINT `sys_c008573` FOREIGN KEY (`instrument_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `statement_rows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `statement_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `order_detail_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `statements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `facility_id` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `account_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_statement_facilities` (`facility_id`),
  CONSTRAINT `fk_statement_facilities` FOREIGN KEY (`facility_id`) REFERENCES `facilities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `user_roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `facility_id` int(11) DEFAULT NULL,
  `role` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `i_use_rol_use_id_fac_id_rol` (`user_id`,`facility_id`,`role`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL DEFAULT '',
  `encrypted_password` varchar(255) DEFAULT NULL,
  `password_salt` varchar(255) DEFAULT NULL,
  `sign_in_count` int(11) DEFAULT '0',
  `current_sign_in_at` datetime DEFAULT NULL,
  `last_sign_in_at` datetime DEFAULT NULL,
  `current_sign_in_ip` varchar(255) DEFAULT NULL,
  `last_sign_in_ip` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_email` (`email`),
  UNIQUE KEY `index_users_on_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `versioned_id` int(11) DEFAULT NULL,
  `versioned_type` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_type` varchar(255) DEFAULT NULL,
  `user_name` varchar(255) DEFAULT NULL,
  `modifications` text,
  `version_number` int(11) DEFAULT NULL,
  `tag` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `reason_for_update` varchar(255) DEFAULT NULL,
  `reverted_from` int(11) DEFAULT NULL,
  `commit_label` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_versions_on_commit_label` (`commit_label`),
  KEY `index_versions_on_created_at` (`created_at`),
  KEY `index_versions_on_tag` (`tag`),
  KEY `i_versions_user_id_user_type` (`user_id`,`user_type`),
  KEY `index_versions_on_user_name` (`user_name`),
  KEY `index_versions_on_number` (`version_number`),
  KEY `i_ver_ver_id_ver_typ` (`versioned_id`,`versioned_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('20100422215947');

INSERT INTO schema_migrations (version) VALUES ('20100423185710');

INSERT INTO schema_migrations (version) VALUES ('20100427192902');

INSERT INTO schema_migrations (version) VALUES ('20100427202835');

INSERT INTO schema_migrations (version) VALUES ('20100428152408');

INSERT INTO schema_migrations (version) VALUES ('20100430184238');

INSERT INTO schema_migrations (version) VALUES ('20100430222700');

INSERT INTO schema_migrations (version) VALUES ('20100506170137');

INSERT INTO schema_migrations (version) VALUES ('20100511164522');

INSERT INTO schema_migrations (version) VALUES ('20100512222847');

INSERT INTO schema_migrations (version) VALUES ('20100521172707');

INSERT INTO schema_migrations (version) VALUES ('20100524203345');

INSERT INTO schema_migrations (version) VALUES ('20100526190311');

INSERT INTO schema_migrations (version) VALUES ('20100527225704');

INSERT INTO schema_migrations (version) VALUES ('20100528190549');

INSERT INTO schema_migrations (version) VALUES ('20100528195301');

INSERT INTO schema_migrations (version) VALUES ('20100528201017');

INSERT INTO schema_migrations (version) VALUES ('20100528201316');

INSERT INTO schema_migrations (version) VALUES ('20100528203109');

INSERT INTO schema_migrations (version) VALUES ('20100528204023');

INSERT INTO schema_migrations (version) VALUES ('20100528212342');

INSERT INTO schema_migrations (version) VALUES ('20100528230042');

INSERT INTO schema_migrations (version) VALUES ('20100528230902');

INSERT INTO schema_migrations (version) VALUES ('20100604214008');

INSERT INTO schema_migrations (version) VALUES ('20100607194341');

INSERT INTO schema_migrations (version) VALUES ('20100607194817');

INSERT INTO schema_migrations (version) VALUES ('20100609205743');

INSERT INTO schema_migrations (version) VALUES ('20100615182659');

INSERT INTO schema_migrations (version) VALUES ('20100615182660');

INSERT INTO schema_migrations (version) VALUES ('20100615182661');

INSERT INTO schema_migrations (version) VALUES ('20100615182662');

INSERT INTO schema_migrations (version) VALUES ('20100615182663');

INSERT INTO schema_migrations (version) VALUES ('20100615182664');

INSERT INTO schema_migrations (version) VALUES ('20100615182665');

INSERT INTO schema_migrations (version) VALUES ('20100615182666');

INSERT INTO schema_migrations (version) VALUES ('20100615182667');

INSERT INTO schema_migrations (version) VALUES ('20100615182668');

INSERT INTO schema_migrations (version) VALUES ('20100615182669');

INSERT INTO schema_migrations (version) VALUES ('20100615182670');

INSERT INTO schema_migrations (version) VALUES ('20100615182671');

INSERT INTO schema_migrations (version) VALUES ('20100615182672');

INSERT INTO schema_migrations (version) VALUES ('20100615182673');

INSERT INTO schema_migrations (version) VALUES ('20100615182674');

INSERT INTO schema_migrations (version) VALUES ('20100615183227');

INSERT INTO schema_migrations (version) VALUES ('20100616192941');

INSERT INTO schema_migrations (version) VALUES ('20100628183740');

INSERT INTO schema_migrations (version) VALUES ('20100628204300');

INSERT INTO schema_migrations (version) VALUES ('20100630233226');

INSERT INTO schema_migrations (version) VALUES ('20100701000551');

INSERT INTO schema_migrations (version) VALUES ('20100701183019');

INSERT INTO schema_migrations (version) VALUES ('20100701232820');

INSERT INTO schema_migrations (version) VALUES ('20100707185202');

INSERT INTO schema_migrations (version) VALUES ('20100707190304');

INSERT INTO schema_migrations (version) VALUES ('20100708000052');

INSERT INTO schema_migrations (version) VALUES ('20100708195447');

INSERT INTO schema_migrations (version) VALUES ('20100708221022');

INSERT INTO schema_migrations (version) VALUES ('20100712194630');

INSERT INTO schema_migrations (version) VALUES ('20100713171653');

INSERT INTO schema_migrations (version) VALUES ('20100713200332');

INSERT INTO schema_migrations (version) VALUES ('20100713224404');

INSERT INTO schema_migrations (version) VALUES ('20100714154110');

INSERT INTO schema_migrations (version) VALUES ('20100715171938');

INSERT INTO schema_migrations (version) VALUES ('20100715223533');

INSERT INTO schema_migrations (version) VALUES ('20100719192104');

INSERT INTO schema_migrations (version) VALUES ('20100721183524');

INSERT INTO schema_migrations (version) VALUES ('20100726171853');

INSERT INTO schema_migrations (version) VALUES ('20100727184318');

INSERT INTO schema_migrations (version) VALUES ('20100729174129');

INSERT INTO schema_migrations (version) VALUES ('20100804191731');

INSERT INTO schema_migrations (version) VALUES ('20100804225934');

INSERT INTO schema_migrations (version) VALUES ('20100805165201');

INSERT INTO schema_migrations (version) VALUES ('20100805175405');

INSERT INTO schema_migrations (version) VALUES ('20100806160008');

INSERT INTO schema_migrations (version) VALUES ('20100806161930');

INSERT INTO schema_migrations (version) VALUES ('20100812170701');

INSERT INTO schema_migrations (version) VALUES ('20100827204813');

INSERT INTO schema_migrations (version) VALUES ('20100908224462');

INSERT INTO schema_migrations (version) VALUES ('20100914171717');

INSERT INTO schema_migrations (version) VALUES ('20100916154915');

INSERT INTO schema_migrations (version) VALUES ('20100917145745');

INSERT INTO schema_migrations (version) VALUES ('20100930180831');

INSERT INTO schema_migrations (version) VALUES ('20101007204359');

INSERT INTO schema_migrations (version) VALUES ('20101007224415');

INSERT INTO schema_migrations (version) VALUES ('20101011172245');

INSERT INTO schema_migrations (version) VALUES ('20101011184759');

INSERT INTO schema_migrations (version) VALUES ('20101012164247');

INSERT INTO schema_migrations (version) VALUES ('20101012181426');

INSERT INTO schema_migrations (version) VALUES ('20101015210647');

INSERT INTO schema_migrations (version) VALUES ('20101015215418');

INSERT INTO schema_migrations (version) VALUES ('20101018192720');

INSERT INTO schema_migrations (version) VALUES ('20101018203424');

INSERT INTO schema_migrations (version) VALUES ('20101018221409');

INSERT INTO schema_migrations (version) VALUES ('20101019163858');

INSERT INTO schema_migrations (version) VALUES ('20101020162405');

INSERT INTO schema_migrations (version) VALUES ('20101027175630');

INSERT INTO schema_migrations (version) VALUES ('20110203223006');

INSERT INTO schema_migrations (version) VALUES ('20110208211613');

INSERT INTO schema_migrations (version) VALUES ('20110215200647');

INSERT INTO schema_migrations (version) VALUES ('20110216002247');

INSERT INTO schema_migrations (version) VALUES ('20110216164102');

INSERT INTO schema_migrations (version) VALUES ('20110216205725');

INSERT INTO schema_migrations (version) VALUES ('20110221225822');

INSERT INTO schema_migrations (version) VALUES ('20110224063354');

INSERT INTO schema_migrations (version) VALUES ('20110314201317');

INSERT INTO schema_migrations (version) VALUES ('20110403013939');

INSERT INTO schema_migrations (version) VALUES ('20110411215240');

INSERT INTO schema_migrations (version) VALUES ('20110412174924');

INSERT INTO schema_migrations (version) VALUES ('20110415224140');

INSERT INTO schema_migrations (version) VALUES ('20110425225944');

INSERT INTO schema_migrations (version) VALUES ('20110426221701');

INSERT INTO schema_migrations (version) VALUES ('20110428204626');

INSERT INTO schema_migrations (version) VALUES ('20110428204714');

INSERT INTO schema_migrations (version) VALUES ('20110428204720');

INSERT INTO schema_migrations (version) VALUES ('20110428204745');

INSERT INTO schema_migrations (version) VALUES ('20110428204746');

INSERT INTO schema_migrations (version) VALUES ('20110506191358');

INSERT INTO schema_migrations (version) VALUES ('20110507055026');

INSERT INTO schema_migrations (version) VALUES ('20110511180455');

INSERT INTO schema_migrations (version) VALUES ('20110608215021');

INSERT INTO schema_migrations (version) VALUES ('20110608222354');

INSERT INTO schema_migrations (version) VALUES ('20110608222406');

INSERT INTO schema_migrations (version) VALUES ('20110608222657');

INSERT INTO schema_migrations (version) VALUES ('20110627182814');

INSERT INTO schema_migrations (version) VALUES ('20110725210324');

INSERT INTO schema_migrations (version) VALUES ('20110729173029');

INSERT INTO schema_migrations (version) VALUES ('20110810225150');

INSERT INTO schema_migrations (version) VALUES ('20110810232349');