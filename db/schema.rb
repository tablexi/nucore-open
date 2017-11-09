# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171109201156) do

  create_table "account_users", force: :cascade do |t|
    t.integer  "account_id", limit: 4,  null: false
    t.integer  "user_id",    limit: 4,  null: false
    t.string   "user_role",  limit: 50, null: false
    t.datetime "created_at",            null: false
    t.integer  "created_by", limit: 4,  null: false
    t.datetime "deleted_at"
    t.integer  "deleted_by", limit: 4
  end

  add_index "account_users", ["account_id"], name: "fk_accounts", using: :btree
  add_index "account_users", ["user_id"], name: "index_account_users_on_user_id", using: :btree

  create_table "accounts", force: :cascade do |t|
    t.string   "type",                   limit: 50,    null: false
    t.string   "account_number",         limit: 50,    null: false
    t.string   "description",            limit: 50,    null: false
    t.datetime "expires_at",                           null: false
    t.string   "name_on_card",           limit: 200
    t.integer  "expiration_month",       limit: 4
    t.integer  "expiration_year",        limit: 4
    t.datetime "created_at",                           null: false
    t.integer  "created_by",             limit: 4,     null: false
    t.datetime "updated_at"
    t.integer  "updated_by",             limit: 4
    t.datetime "suspended_at"
    t.text     "remittance_information", limit: 65535
    t.integer  "facility_id",            limit: 4
    t.integer  "affiliate_id",           limit: 4
    t.string   "affiliate_other",        limit: 255
    t.string   "outside_contact_info",   limit: 255
    t.string   "ar_number",              limit: 255
  end

  add_index "accounts", ["affiliate_id"], name: "index_accounts_on_affiliate_id", using: :btree
  add_index "accounts", ["facility_id"], name: "fk_account_facility_id", using: :btree

  create_table "affiliates", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.boolean  "subaffiliates_enabled",             default: false, null: false
  end

  create_table "budgeted_chart_strings", force: :cascade do |t|
    t.string   "fund",       limit: 20, null: false
    t.string   "dept",       limit: 20, null: false
    t.string   "project",    limit: 20
    t.string   "activity",   limit: 20
    t.string   "account",    limit: 20
    t.datetime "starts_at",             null: false
    t.datetime "expires_at",            null: false
  end

  create_table "bulk_email_jobs", force: :cascade do |t|
    t.integer  "facility_id",     limit: 4
    t.integer  "user_id",         limit: 4,     null: false
    t.string   "subject",         limit: 255,   null: false
    t.text     "body",            limit: 65535, null: false
    t.text     "recipients",      limit: 65535, null: false
    t.text     "search_criteria", limit: 65535, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "bulk_email_jobs", ["facility_id"], name: "fk_rails_37dbedd2b3", using: :btree
  add_index "bulk_email_jobs", ["user_id"], name: "fk_rails_7cd8662ccc", using: :btree

  create_table "bundle_products", force: :cascade do |t|
    t.integer "bundle_product_id", limit: 4, null: false
    t.integer "product_id",        limit: 4, null: false
    t.integer "quantity",          limit: 4, null: false
  end

  add_index "bundle_products", ["bundle_product_id"], name: "fk_bundle_prod_prod", using: :btree
  add_index "bundle_products", ["product_id"], name: "fk_bundle_prod_bundle", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,          default: 0, null: false
    t.integer  "attempts",   limit: 4,          default: 0, null: false
    t.text     "handler",    limit: 4294967295,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "email_events", force: :cascade do |t|
    t.integer  "user_id",      limit: 4,   null: false
    t.string   "key",          limit: 255, null: false
    t.datetime "last_sent_at",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_events", ["user_id", "key"], name: "index_email_events_on_user_id_and_key", unique: true, using: :btree

  create_table "external_service_passers", force: :cascade do |t|
    t.integer  "external_service_id", limit: 4
    t.integer  "passer_id",           limit: 4
    t.string   "passer_type",         limit: 255
    t.boolean  "active",                          default: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "external_service_passers", ["external_service_id"], name: "index_external_service_passers_on_external_service_id", using: :btree
  add_index "external_service_passers", ["passer_id", "passer_type"], name: "i_external_passer_id", using: :btree

  create_table "external_service_receivers", force: :cascade do |t|
    t.integer  "external_service_id", limit: 4
    t.integer  "receiver_id",         limit: 4
    t.string   "receiver_type",       limit: 255
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "external_id",         limit: 255
    t.text     "response_data",       limit: 65535
    t.boolean  "manages_quantity",                  default: false, null: false
  end

  add_index "external_service_receivers", ["external_service_id"], name: "index_external_service_receivers_on_external_service_id", using: :btree
  add_index "external_service_receivers", ["receiver_id", "receiver_type"], name: "i_external_receiver_id", using: :btree

  create_table "external_services", force: :cascade do |t|
    t.string   "type",       limit: 255
    t.string   "location",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "facilities", force: :cascade do |t|
    t.string   "name",                         limit: 200,                   null: false
    t.string   "abbreviation",                 limit: 50,                    null: false
    t.string   "url_name",                     limit: 50,                    null: false
    t.boolean  "is_active",                                                  null: false
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.text     "description",                  limit: 65535
    t.boolean  "accepts_cc",                                 default: true
    t.boolean  "accepts_po",                                 default: true
    t.boolean  "accepts_multi_add",                          default: false, null: false
    t.text     "short_description",            limit: 65535,                 null: false
    t.text     "address",                      limit: 65535
    t.string   "phone_number",                 limit: 255
    t.string   "fax_number",                   limit: 255
    t.string   "email",                        limit: 255
    t.string   "journal_mask",                 limit: 50,                    null: false
    t.boolean  "show_instrument_availability",               default: false, null: false
    t.string   "order_notification_recipient", limit: 255
    t.boolean  "sanger_sequencing_enabled",                  default: false, null: false
  end

  add_index "facilities", ["abbreviation"], name: "index_facilities_on_abbreviation", unique: true, using: :btree
  add_index "facilities", ["is_active", "name"], name: "index_facilities_on_is_active_and_name", using: :btree
  add_index "facilities", ["name"], name: "index_facilities_on_name", unique: true, using: :btree
  add_index "facilities", ["url_name"], name: "index_facilities_on_url_name", unique: true, using: :btree

  create_table "facility_accounts", force: :cascade do |t|
    t.integer  "facility_id",     limit: 4,  null: false
    t.string   "account_number",  limit: 50, null: false
    t.boolean  "is_active",                  null: false
    t.integer  "created_by",      limit: 4,  null: false
    t.datetime "created_at",                 null: false
    t.integer  "revenue_account", limit: 4,  null: false
  end

  add_index "facility_accounts", ["facility_id"], name: "fk_facilities", using: :btree

  create_table "instrument_statuses", force: :cascade do |t|
    t.integer  "instrument_id", limit: 4, null: false
    t.boolean  "is_on",                   null: false
    t.datetime "created_at",              null: false
  end

  add_index "instrument_statuses", ["instrument_id"], name: "fk_int_stats_product", using: :btree

  create_table "journal_cutoff_dates", force: :cascade do |t|
    t.datetime "cutoff_date"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "journal_rows", force: :cascade do |t|
    t.integer "journal_id",      limit: 4,                           null: false
    t.integer "order_detail_id", limit: 4
    t.string  "account",         limit: 5
    t.decimal "amount",                      precision: 9, scale: 2, null: false
    t.string  "description",     limit: 512
    t.integer "account_id",      limit: 4
  end

  add_index "journal_rows", ["account_id"], name: "index_journal_rows_on_account_id", using: :btree
  add_index "journal_rows", ["journal_id"], name: "index_journal_rows_on_journal_id", using: :btree
  add_index "journal_rows", ["order_detail_id"], name: "index_journal_rows_on_order_detail_id", using: :btree

  create_table "journals", force: :cascade do |t|
    t.integer  "facility_id",       limit: 4
    t.string   "reference",         limit: 50
    t.string   "description",       limit: 200
    t.boolean  "is_successful"
    t.integer  "created_by",        limit: 4,   null: false
    t.datetime "created_at",                    null: false
    t.integer  "updated_by",        limit: 4
    t.datetime "updated_at"
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
    t.datetime "journal_date",                  null: false
  end

  add_index "journals", ["facility_id"], name: "index_journals_on_facility_id", using: :btree

  create_table "log_events", force: :cascade do |t|
    t.integer  "loggable_id",   limit: 4
    t.string   "loggable_type", limit: 255
    t.string   "event_type",    limit: 255
    t.integer  "user_id",       limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.datetime "event_time"
  end

  add_index "log_events", ["loggable_type", "loggable_id"], name: "index_log_events_loggable", using: :btree
  add_index "log_events", ["user_id"], name: "index_log_events_on_user_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.string   "type",         limit: 255, null: false
    t.integer  "subject_id",   limit: 4,   null: false
    t.string   "subject_type", limit: 255, null: false
    t.integer  "user_id",      limit: 4,   null: false
    t.string   "notice",       limit: 255, null: false
    t.datetime "dismissed_at"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "notifications", ["subject_id", "subject_type"], name: "index_notifications_on_subject_id_and_subject_type", using: :btree
  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

  create_table "order_details", force: :cascade do |t|
    t.integer  "order_id",                limit: 4,                                              null: false
    t.integer  "parent_order_detail_id",  limit: 4
    t.integer  "product_id",              limit: 4,                                              null: false
    t.integer  "quantity",                limit: 4,                                              null: false
    t.integer  "price_policy_id",         limit: 4
    t.decimal  "actual_cost",                           precision: 10, scale: 2
    t.decimal  "actual_subsidy",                        precision: 10, scale: 2
    t.integer  "assigned_user_id",        limit: 4
    t.decimal  "estimated_cost",                        precision: 10, scale: 2
    t.decimal  "estimated_subsidy",                     precision: 10, scale: 2
    t.integer  "response_set_id",         limit: 4
    t.integer  "account_id",              limit: 4
    t.datetime "dispute_at"
    t.integer  "dispute_by_id",           limit: 4
    t.string   "dispute_reason",          limit: 200
    t.datetime "dispute_resolved_at"
    t.string   "dispute_resolved_reason", limit: 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_status_id",         limit: 4
    t.string   "state",                   limit: 50
    t.integer  "group_id",                limit: 4
    t.integer  "bundle_product_id",       limit: 4
    t.datetime "fulfilled_at"
    t.datetime "reviewed_at"
    t.integer  "statement_id",            limit: 4
    t.integer  "journal_id",              limit: 4
    t.string   "reconciled_note",         limit: 255
    t.integer  "created_by",              limit: 4,                                              null: false
    t.integer  "product_accessory_id",    limit: 4
    t.boolean  "problem",                                                        default: false, null: false
    t.datetime "reconciled_at"
    t.integer  "project_id",              limit: 4
    t.text     "note",                    limit: 65535
    t.datetime "canceled_at"
    t.integer  "canceled_by",             limit: 4
    t.string   "canceled_reason",         limit: 255
  end

  add_index "order_details", ["account_id"], name: "fk_od_accounts", using: :btree
  add_index "order_details", ["assigned_user_id"], name: "index_order_details_on_assigned_user_id", using: :btree
  add_index "order_details", ["bundle_product_id"], name: "fk_bundle_prod_id", using: :btree
  add_index "order_details", ["dispute_by_id"], name: "fk_rails_14de4f1c86", using: :btree
  add_index "order_details", ["group_id"], name: "index_order_details_on_group_id", using: :btree
  add_index "order_details", ["journal_id"], name: "index_order_details_on_journal_id", using: :btree
  add_index "order_details", ["order_id"], name: "fk_rails_e5976611fd", using: :btree
  add_index "order_details", ["order_status_id"], name: "index_order_details_on_order_status_id", using: :btree
  add_index "order_details", ["parent_order_detail_id"], name: "fk_rails_cc2adae8c3", using: :btree
  add_index "order_details", ["price_policy_id"], name: "fk_rails_555b721183", using: :btree
  add_index "order_details", ["problem"], name: "index_order_details_on_problem", using: :btree
  add_index "order_details", ["product_accessory_id"], name: "fk_rails_e4f0ef56a6", using: :btree
  add_index "order_details", ["product_id"], name: "fk_rails_4f2ac9473b", using: :btree
  add_index "order_details", ["project_id"], name: "index_order_details_on_project_id", using: :btree
  add_index "order_details", ["response_set_id"], name: "index_order_details_on_response_set_id", using: :btree
  add_index "order_details", ["state"], name: "index_order_details_on_state", using: :btree
  add_index "order_details", ["statement_id"], name: "index_order_details_on_statement_id", using: :btree

  create_table "order_imports", force: :cascade do |t|
    t.integer  "facility_id",    limit: 4
    t.integer  "upload_file_id", limit: 4,                 null: false
    t.integer  "error_file_id",  limit: 4
    t.boolean  "fail_on_error",            default: true
    t.boolean  "send_receipts",            default: false
    t.integer  "created_by",     limit: 4,                 null: false
    t.datetime "processed_at"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "order_imports", ["created_by"], name: "index_order_imports_on_created_by", using: :btree
  add_index "order_imports", ["error_file_id"], name: "index_order_imports_on_error_file_id", using: :btree
  add_index "order_imports", ["facility_id"], name: "i_order_imports_facility_id", using: :btree
  add_index "order_imports", ["upload_file_id"], name: "index_order_imports_on_upload_file_id", using: :btree

  create_table "order_statuses", force: :cascade do |t|
    t.string  "name",        limit: 50, null: false
    t.integer "facility_id", limit: 4
    t.integer "parent_id",   limit: 4
    t.integer "lft",         limit: 4
    t.integer "rgt",         limit: 4
  end

  add_index "order_statuses", ["facility_id", "parent_id", "name"], name: "index_order_statuses_on_facility_id_and_parent_id_and_name", unique: true, using: :btree
  add_index "order_statuses", ["parent_id"], name: "index_order_statuses_on_parent_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.integer  "account_id",          limit: 4
    t.integer  "user_id",             limit: 4,  null: false
    t.integer  "created_by",          limit: 4,  null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.datetime "ordered_at"
    t.integer  "facility_id",         limit: 4
    t.string   "state",               limit: 50
    t.integer  "merge_with_order_id", limit: 4
    t.integer  "order_import_id",     limit: 4
  end

  add_index "orders", ["account_id"], name: "fk_rails_144e25bef6", using: :btree
  add_index "orders", ["facility_id"], name: "index_orders_on_facility_id", using: :btree
  add_index "orders", ["merge_with_order_id"], name: "index_orders_on_merge_with_order_id", using: :btree
  add_index "orders", ["order_import_id"], name: "index_orders_on_order_import_id", using: :btree
  add_index "orders", ["state"], name: "index_orders_on_state", using: :btree
  add_index "orders", ["user_id"], name: "index_orders_on_user_id", using: :btree

  create_table "payments", force: :cascade do |t|
    t.integer  "account_id",     limit: 4,                                          null: false
    t.integer  "statement_id",   limit: 4
    t.string   "source",         limit: 255,                                        null: false
    t.string   "source_id",      limit: 255
    t.decimal  "amount",                     precision: 10, scale: 2,               null: false
    t.integer  "paid_by_id",     limit: 4
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.decimal  "processing_fee",             precision: 10, scale: 2, default: 0.0, null: false
  end

  add_index "payments", ["account_id"], name: "index_payments_on_account_id", using: :btree
  add_index "payments", ["paid_by_id"], name: "index_payments_on_paid_by_id", using: :btree
  add_index "payments", ["statement_id"], name: "index_payments_on_statement_id", using: :btree

  create_table "price_group_members", force: :cascade do |t|
    t.string  "type",           limit: 50, null: false
    t.integer "price_group_id", limit: 4,  null: false
    t.integer "user_id",        limit: 4
    t.integer "account_id",     limit: 4
  end

  add_index "price_group_members", ["account_id"], name: "index_price_group_members_on_account_id", using: :btree
  add_index "price_group_members", ["price_group_id"], name: "fk_rails_0425013e5b", using: :btree
  add_index "price_group_members", ["user_id"], name: "index_price_group_members_on_user_id", using: :btree

  create_table "price_group_products", force: :cascade do |t|
    t.integer  "price_group_id",     limit: 4, null: false
    t.integer  "product_id",         limit: 4, null: false
    t.integer  "reservation_window", limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "price_group_products", ["price_group_id"], name: "index_price_group_products_on_price_group_id", using: :btree
  add_index "price_group_products", ["product_id"], name: "index_price_group_products_on_product_id", using: :btree

  create_table "price_groups", force: :cascade do |t|
    t.integer "facility_id",    limit: 4
    t.string  "name",           limit: 50,                null: false
    t.integer "display_order",  limit: 4,                 null: false
    t.boolean "is_internal",                              null: false
    t.boolean "admin_editable",            default: true, null: false
  end

  add_index "price_groups", ["facility_id", "name"], name: "index_price_groups_on_facility_id_and_name", unique: true, using: :btree

  create_table "price_policies", force: :cascade do |t|
    t.string   "type",              limit: 50,                                           null: false
    t.integer  "product_id",        limit: 4
    t.integer  "price_group_id",    limit: 4,                                            null: false
    t.boolean  "can_purchase",                                           default: false, null: false
    t.datetime "start_date",                                                             null: false
    t.decimal  "unit_cost",                     precision: 10, scale: 2
    t.decimal  "unit_subsidy",                  precision: 10, scale: 2
    t.decimal  "usage_rate",                    precision: 12, scale: 4
    t.decimal  "minimum_cost",                  precision: 10, scale: 2
    t.decimal  "cancellation_cost",             precision: 10, scale: 2
    t.decimal  "usage_subsidy",                 precision: 12, scale: 4
    t.datetime "expire_date",                                                            null: false
    t.string   "charge_for",        limit: 255
    t.string   "legacy_rates",      limit: 255
  end

  add_index "price_policies", ["price_group_id"], name: "fk_rails_74aa223960", using: :btree
  add_index "price_policies", ["product_id"], name: "index_price_policies_on_product_id", using: :btree

  create_table "product_access_groups", force: :cascade do |t|
    t.integer  "product_id", limit: 4,   null: false
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "product_access_groups", ["product_id"], name: "index_product_access_groups_on_product_id", using: :btree

  create_table "product_access_schedule_rules", id: false, force: :cascade do |t|
    t.integer "product_access_group_id", limit: 4, null: false
    t.integer "schedule_rule_id",        limit: 4, null: false
  end

  add_index "product_access_schedule_rules", ["product_access_group_id"], name: "index_product_access_schedule_rules_on_product_access_group_id", using: :btree
  add_index "product_access_schedule_rules", ["schedule_rule_id"], name: "index_product_access_schedule_rules_on_schedule_rule_id", using: :btree

  create_table "product_accessories", force: :cascade do |t|
    t.integer  "product_id",   limit: 4,                        null: false
    t.integer  "accessory_id", limit: 4,                        null: false
    t.string   "scaling_type", limit: 255, default: "quantity", null: false
    t.datetime "deleted_at"
  end

  add_index "product_accessories", ["accessory_id"], name: "index_product_accessories_on_accessory_id", using: :btree
  add_index "product_accessories", ["product_id"], name: "index_product_accessories_on_product_id", using: :btree

  create_table "product_users", force: :cascade do |t|
    t.integer  "product_id",              limit: 4, null: false
    t.integer  "user_id",                 limit: 4, null: false
    t.integer  "approved_by",             limit: 4, null: false
    t.datetime "approved_at",                       null: false
    t.integer  "product_access_group_id", limit: 4
    t.datetime "requested_at"
  end

  add_index "product_users", ["product_access_group_id"], name: "index_product_users_on_product_access_group_id", using: :btree
  add_index "product_users", ["product_id"], name: "fk_products", using: :btree
  add_index "product_users", ["user_id"], name: "index_product_users_on_user_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "type",                         limit: 50,                       null: false
    t.integer  "facility_id",                  limit: 4,                        null: false
    t.string   "name",                         limit: 200,                      null: false
    t.string   "url_name",                     limit: 50,                       null: false
    t.text     "description",                  limit: 65535
    t.integer  "schedule_id",                  limit: 4
    t.boolean  "requires_approval",                                             null: false
    t.integer  "initial_order_status_id",      limit: 4
    t.boolean  "is_archived",                                                   null: false
    t.boolean  "is_hidden",                                                     null: false
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.integer  "min_reserve_mins",             limit: 4
    t.integer  "max_reserve_mins",             limit: 4
    t.integer  "min_cancel_hours",             limit: 4
    t.integer  "facility_account_id",          limit: 4
    t.string   "account",                      limit: 5
    t.boolean  "show_details",                               default: false,    null: false
    t.integer  "auto_cancel_mins",             limit: 4
    t.string   "contact_email",                limit: 255
    t.integer  "reserve_interval",             limit: 4
    t.integer  "lock_window",                  limit: 4,     default: 0,        null: false
    t.text     "training_request_contacts",    limit: 65535
    t.integer  "cutoff_hours",                 limit: 4,     default: 0,        null: false
    t.string   "dashboard_token",              limit: 255
    t.string   "user_notes_field_mode",        limit: 255,   default: "hidden", null: false
    t.string   "user_notes_label",             limit: 255
    t.string   "order_notification_recipient", limit: 255
  end

  add_index "products", ["dashboard_token"], name: "index_products_on_dashboard_token", using: :btree
  add_index "products", ["facility_account_id"], name: "fk_facility_accounts", using: :btree
  add_index "products", ["facility_id"], name: "fk_rails_0c9fa1afbe", using: :btree
  add_index "products", ["initial_order_status_id"], name: "index_products_on_initial_order_status_id", using: :btree
  add_index "products", ["schedule_id"], name: "i_instruments_schedule_id", using: :btree
  add_index "products", ["url_name"], name: "index_products_on_url_name", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name",        limit: 255,                  null: false
    t.text     "description", limit: 65535
    t.integer  "facility_id", limit: 4,                    null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.boolean  "active",                    default: true, null: false
  end

  add_index "projects", ["facility_id", "name"], name: "index_projects_on_facility_id_and_name", unique: true, using: :btree
  add_index "projects", ["facility_id"], name: "index_projects_on_facility_id", using: :btree

  create_table "relays", force: :cascade do |t|
    t.integer  "instrument_id",       limit: 4
    t.string   "ip",                  limit: 15
    t.integer  "port",                limit: 4
    t.string   "username",            limit: 50
    t.string   "password",            limit: 50
    t.boolean  "auto_logout"
    t.string   "type",                limit: 255
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "auto_logout_minutes", limit: 4,   default: 60
  end

  add_index "relays", ["instrument_id"], name: "index_relays_on_instrument_id", using: :btree

  create_table "reservations", force: :cascade do |t|
    t.integer  "order_detail_id",     limit: 4
    t.integer  "product_id",          limit: 4,   null: false
    t.datetime "reserve_start_at",                null: false
    t.datetime "reserve_end_at"
    t.datetime "actual_start_at"
    t.datetime "actual_end_at"
    t.string   "admin_note",          limit: 255
    t.string   "type",                limit: 255
    t.string   "category",            limit: 255
    t.integer  "expires_mins_before", limit: 4
    t.integer  "created_by_id",       limit: 4
    t.datetime "deleted_at"
  end

  add_index "reservations", ["created_by_id"], name: "index_reservations_on_created_by_id", using: :btree
  add_index "reservations", ["deleted_at"], name: "index_reservations_on_deleted_at", using: :btree
  add_index "reservations", ["order_detail_id"], name: "res_od_uniq_fk", unique: true, using: :btree
  add_index "reservations", ["product_id", "reserve_start_at"], name: "index_reservations_on_product_id_and_reserve_start_at", using: :btree

  create_table "sanger_seq_product_groups", force: :cascade do |t|
    t.integer  "product_id", limit: 4,   null: false
    t.string   "group",      limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sanger_seq_product_groups", ["product_id"], name: "index_sanger_seq_product_groups_on_product_id", unique: true, using: :btree

  create_table "sanger_sequencing_batches", force: :cascade do |t|
    t.integer  "created_by_id",   limit: 4
    t.text     "well_plates_raw", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "facility_id",     limit: 4
    t.string   "group",           limit: 255
  end

  add_index "sanger_sequencing_batches", ["created_by_id"], name: "index_sanger_sequencing_batches_on_created_by_id", using: :btree
  add_index "sanger_sequencing_batches", ["facility_id"], name: "index_sanger_sequencing_batches_on_facility_id", using: :btree
  add_index "sanger_sequencing_batches", ["group"], name: "index_sanger_sequencing_batches_on_group", using: :btree

  create_table "sanger_sequencing_samples", force: :cascade do |t|
    t.integer  "submission_id",      limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "customer_sample_id", limit: 255
  end

  add_index "sanger_sequencing_samples", ["submission_id"], name: "index_sanger_sequencing_samples_on_submission_id", using: :btree

  create_table "sanger_sequencing_submissions", force: :cascade do |t|
    t.integer  "order_detail_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "batch_id",        limit: 4
  end

  add_index "sanger_sequencing_submissions", ["batch_id"], name: "fk_rails_24eeb2c9b4", using: :btree
  add_index "sanger_sequencing_submissions", ["order_detail_id"], name: "index_sanger_sequencing_submissions_on_order_detail_id", using: :btree

  create_table "schedule_rules", force: :cascade do |t|
    t.integer "product_id",       limit: 4,                                        null: false
    t.decimal "discount_percent",           precision: 10, scale: 2, default: 0.0, null: false
    t.integer "start_hour",       limit: 4,                                        null: false
    t.integer "start_min",        limit: 4,                                        null: false
    t.integer "end_hour",         limit: 4,                                        null: false
    t.integer "end_min",          limit: 4,                                        null: false
    t.boolean "on_sun",                                                            null: false
    t.boolean "on_mon",                                                            null: false
    t.boolean "on_tue",                                                            null: false
    t.boolean "on_wed",                                                            null: false
    t.boolean "on_thu",                                                            null: false
    t.boolean "on_fri",                                                            null: false
    t.boolean "on_sat",                                                            null: false
  end

  add_index "schedule_rules", ["product_id"], name: "index_schedule_rules_on_product_id", using: :btree

  create_table "schedules", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.integer  "facility_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "schedules", ["facility_id"], name: "i_schedules_facility_id", using: :btree

  create_table "secure_rooms_alarm_events", force: :cascade do |t|
    t.text     "additional_data",   limit: 65535
    t.string   "class_code",        limit: 255
    t.string   "event_code",        limit: 255
    t.string   "event_description", limit: 255
    t.string   "mac_address",       limit: 255
    t.string   "message_id",        limit: 255
    t.datetime "message_time"
    t.string   "message_type",      limit: 255
    t.string   "priority",          limit: 255
    t.string   "task_code",         limit: 255
    t.string   "task_description",  limit: 255
    t.text     "raw_post",          limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "secure_rooms_card_readers", force: :cascade do |t|
    t.integer  "product_id",            limit: 4,                  null: false
    t.string   "card_reader_number",    limit: 255
    t.string   "control_device_number", limit: 255
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "description",           limit: 255
    t.boolean  "direction_in",                      default: true, null: false
    t.string   "tablet_token",          limit: 255
  end

  add_index "secure_rooms_card_readers", ["card_reader_number", "control_device_number"], name: "i_secure_room_reader_ids", unique: true, using: :btree
  add_index "secure_rooms_card_readers", ["product_id"], name: "index_secure_rooms_card_readers_on_product_id", using: :btree
  add_index "secure_rooms_card_readers", ["tablet_token"], name: "index_secure_rooms_card_readers_on_tablet_token", unique: true, using: :btree

  create_table "secure_rooms_events", force: :cascade do |t|
    t.integer  "card_reader_id",  limit: 4,   null: false
    t.integer  "user_id",         limit: 4,   null: false
    t.datetime "occurred_at"
    t.string   "outcome",         limit: 255
    t.string   "outcome_details", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "account_id",      limit: 4
  end

  add_index "secure_rooms_events", ["account_id"], name: "index_secure_rooms_events_on_account_id", using: :btree
  add_index "secure_rooms_events", ["card_reader_id"], name: "index_secure_rooms_events_on_card_reader_id", using: :btree
  add_index "secure_rooms_events", ["user_id"], name: "index_secure_rooms_events_on_user_id", using: :btree

  create_table "secure_rooms_occupancies", force: :cascade do |t|
    t.integer  "product_id",      limit: 4, null: false
    t.integer  "user_id",         limit: 4, null: false
    t.integer  "account_id",      limit: 4
    t.integer  "entry_event_id",  limit: 4
    t.datetime "entry_at"
    t.integer  "exit_event_id",   limit: 4
    t.datetime "exit_at"
    t.datetime "orphaned_at"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "order_detail_id", limit: 4
  end

  add_index "secure_rooms_occupancies", ["account_id"], name: "index_secure_rooms_occupancies_on_account_id", using: :btree
  add_index "secure_rooms_occupancies", ["entry_event_id"], name: "index_secure_rooms_occupancies_on_entry_event_id", using: :btree
  add_index "secure_rooms_occupancies", ["exit_event_id"], name: "index_secure_rooms_occupancies_on_exit_event_id", using: :btree
  add_index "secure_rooms_occupancies", ["order_detail_id"], name: "index_secure_rooms_occupancies_on_order_detail_id", using: :btree
  add_index "secure_rooms_occupancies", ["product_id"], name: "index_secure_rooms_occupancies_on_product_id", using: :btree
  add_index "secure_rooms_occupancies", ["user_id"], name: "index_secure_rooms_occupancies_on_user_id", using: :btree

  create_table "splits", force: :cascade do |t|
    t.integer "parent_split_account_id", limit: 4,                         null: false
    t.integer "subaccount_id",           limit: 4,                         null: false
    t.decimal "percent",                           precision: 6, scale: 3, null: false
    t.boolean "apply_remainder",                                           null: false
  end

  add_index "splits", ["parent_split_account_id"], name: "index_splits_on_parent_split_account_id", using: :btree
  add_index "splits", ["subaccount_id"], name: "index_splits_on_subaccount_id", using: :btree

  create_table "statement_rows", force: :cascade do |t|
    t.integer  "statement_id",    limit: 4, null: false
    t.integer  "order_detail_id", limit: 4, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "statement_rows", ["order_detail_id"], name: "index_statement_rows_on_order_detail_id", using: :btree
  add_index "statement_rows", ["statement_id"], name: "index_statement_rows_on_statement_id", using: :btree

  create_table "statements", force: :cascade do |t|
    t.integer  "facility_id", limit: 4, null: false
    t.integer  "created_by",  limit: 4, null: false
    t.datetime "created_at",            null: false
    t.integer  "account_id",  limit: 4, null: false
  end

  add_index "statements", ["account_id"], name: "index_statements_on_account_id", using: :btree
  add_index "statements", ["facility_id"], name: "fk_statement_facilities", using: :btree

  create_table "stored_files", force: :cascade do |t|
    t.integer  "order_detail_id",   limit: 4
    t.integer  "product_id",        limit: 4
    t.string   "name",              limit: 200, null: false
    t.string   "file_type",         limit: 50,  null: false
    t.integer  "created_by",        limit: 4,   null: false
    t.datetime "created_at",                    null: false
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
  end

  add_index "stored_files", ["order_detail_id"], name: "fk_files_od", using: :btree
  add_index "stored_files", ["product_id"], name: "fk_files_product", using: :btree

  create_table "training_requests", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "product_id", limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "training_requests", ["product_id"], name: "index_training_requests_on_product_id", using: :btree
  add_index "training_requests", ["user_id"], name: "index_training_requests_on_user_id", using: :btree

  create_table "user_preferences", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255, null: false
    t.string   "value",      limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "user_preferences", ["user_id", "name"], name: "index_user_preferences_on_user_id_and_name", unique: true, using: :btree

  create_table "user_roles", force: :cascade do |t|
    t.integer "user_id",     limit: 4,   null: false
    t.integer "facility_id", limit: 4
    t.string  "role",        limit: 255, null: false
  end

  add_index "user_roles", ["facility_id"], name: "fk_rails_dca27403dd", using: :btree
  add_index "user_roles", ["user_id", "facility_id", "role"], name: "index_user_roles_on_user_id_and_facility_id_and_role", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username",               limit: 255,              null: false
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255
    t.string   "password_salt",          limit: 255
    t.integer  "sign_in_count",          limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.integer  "uid",                    limit: 4
    t.datetime "deactivated_at"
    t.string   "card_number",            limit: 255
  end

  add_index "users", ["card_number"], name: "index_users_on_card_number", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 191,        null: false
    t.integer  "item_id",    limit: 4,          null: false
    t.string   "event",      limit: 255,        null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object",     limit: 4294967295
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "vestal_versions", force: :cascade do |t|
    t.integer  "versioned_id",      limit: 4
    t.string   "versioned_type",    limit: 255
    t.integer  "user_id",           limit: 4
    t.string   "user_type",         limit: 255
    t.string   "user_name",         limit: 255
    t.text     "modifications",     limit: 65535
    t.integer  "version_number",    limit: 4
    t.string   "tag",               limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "reason_for_update", limit: 255
    t.integer  "reverted_from",     limit: 4
    t.string   "commit_label",      limit: 255
  end

  add_index "vestal_versions", ["commit_label"], name: "index_vestal_versions_on_commit_label", using: :btree
  add_index "vestal_versions", ["created_at"], name: "index_vestal_versions_on_created_at", using: :btree
  add_index "vestal_versions", ["tag"], name: "index_vestal_versions_on_tag", using: :btree
  add_index "vestal_versions", ["user_id", "user_type"], name: "index_vestal_versions_on_user_id_and_user_type", using: :btree
  add_index "vestal_versions", ["user_name"], name: "index_vestal_versions_on_user_name", using: :btree
  add_index "vestal_versions", ["version_number"], name: "index_vestal_versions_on_version_number", using: :btree
  add_index "vestal_versions", ["versioned_id", "versioned_type"], name: "index_vestal_versions_on_versioned_id_and_versioned_type", using: :btree

  add_foreign_key "account_users", "accounts", name: "fk_accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "accounts", "facilities", name: "fk_account_facility_id"
  add_foreign_key "bulk_email_jobs", "facilities"
  add_foreign_key "bulk_email_jobs", "users"
  add_foreign_key "bundle_products", "products", column: "bundle_product_id", name: "fk_bundle_prod_prod"
  add_foreign_key "bundle_products", "products", name: "fk_bundle_prod_bundle"
  add_foreign_key "email_events", "users"
  add_foreign_key "facility_accounts", "facilities", name: "fk_facilities"
  add_foreign_key "instrument_statuses", "products", column: "instrument_id", name: "fk_int_stats_product"
  add_foreign_key "journal_rows", "accounts"
  add_foreign_key "journal_rows", "journals"
  add_foreign_key "journal_rows", "order_details"
  add_foreign_key "log_events", "users"
  add_foreign_key "order_details", "accounts", name: "fk_od_accounts"
  add_foreign_key "order_details", "journals"
  add_foreign_key "order_details", "order_details", column: "parent_order_detail_id"
  add_foreign_key "order_details", "order_statuses"
  add_foreign_key "order_details", "orders"
  add_foreign_key "order_details", "price_policies"
  add_foreign_key "order_details", "product_accessories"
  add_foreign_key "order_details", "products"
  add_foreign_key "order_details", "products", column: "bundle_product_id", name: "fk_bundle_prod_id"
  add_foreign_key "order_details", "statements"
  add_foreign_key "order_details", "users", column: "assigned_user_id"
  add_foreign_key "order_details", "users", column: "dispute_by_id"
  add_foreign_key "order_imports", "facilities", name: "fk_order_imports_facilities"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "facilities"
  add_foreign_key "orders", "order_imports"
  add_foreign_key "orders", "orders", column: "merge_with_order_id"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "statements"
  add_foreign_key "payments", "users", column: "paid_by_id"
  add_foreign_key "price_group_members", "accounts"
  add_foreign_key "price_group_members", "price_groups"
  add_foreign_key "price_group_members", "users"
  add_foreign_key "price_groups", "facilities"
  add_foreign_key "price_policies", "price_groups"
  add_foreign_key "product_users", "products", name: "fk_products"
  add_foreign_key "product_users", "users"
  add_foreign_key "products", "facilities"
  add_foreign_key "products", "facility_accounts", name: "fk_facility_accounts"
  add_foreign_key "products", "schedules", name: "fk_instruments_schedule"
  add_foreign_key "projects", "facilities"
  add_foreign_key "reservations", "order_details"
  add_foreign_key "reservations", "products", name: "reservations_instrument_id_fk"
  add_foreign_key "reservations", "users", column: "created_by_id"
  add_foreign_key "sanger_seq_product_groups", "products"
  add_foreign_key "sanger_sequencing_batches", "facilities"
  add_foreign_key "sanger_sequencing_samples", "sanger_sequencing_submissions", column: "submission_id", on_delete: :cascade
  add_foreign_key "sanger_sequencing_submissions", "sanger_sequencing_batches", column: "batch_id", on_delete: :nullify
  add_foreign_key "schedule_rules", "products"
  add_foreign_key "schedules", "facilities", name: "fk_schedules_facility"
  add_foreign_key "secure_rooms_card_readers", "products"
  add_foreign_key "secure_rooms_events", "accounts"
  add_foreign_key "secure_rooms_occupancies", "accounts"
  add_foreign_key "secure_rooms_occupancies", "order_details"
  add_foreign_key "secure_rooms_occupancies", "products"
  add_foreign_key "secure_rooms_occupancies", "secure_rooms_events", column: "entry_event_id"
  add_foreign_key "secure_rooms_occupancies", "secure_rooms_events", column: "exit_event_id"
  add_foreign_key "secure_rooms_occupancies", "users"
  add_foreign_key "statement_rows", "order_details"
  add_foreign_key "statement_rows", "statements"
  add_foreign_key "statements", "accounts"
  add_foreign_key "statements", "facilities", name: "fk_statement_facilities"
  add_foreign_key "stored_files", "order_details", name: "fk_files_od"
  add_foreign_key "stored_files", "products", name: "fk_files_product"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_roles", "facilities"
  add_foreign_key "user_roles", "users"
end
