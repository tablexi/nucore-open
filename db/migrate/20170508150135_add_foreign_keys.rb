class AddForeignKeys < ActiveRecord::Migration
  def change
    add_index :notifications, [:subject_id, :subject_type]
    add_index :order_details, :project_id
    add_index :order_statuses, :parent_id
    add_index :orders, :merge_with_order_id
    add_index :price_group_members, :account_id
    add_index :products, :initial_order_status_id

    # The dartmouth database violates this one
    add_foreign_key :account_users, :users

    add_foreign_key :order_details, :users, column: :assigned_user_id
    add_foreign_key :order_details, :journals
    add_foreign_key :order_details, :order_statuses
    add_foreign_key :order_details, :statements
    add_foreign_key :orders, :order_imports
    add_foreign_key :orders, :orders, column: :merge_with_order_id

    #The UIC and Dartmouth databases violate this
    add_foreign_key :orders, :users

    add_foreign_key :price_group_members, :accounts

    # This is in a migration, the Dartmouth database has it, the UIC
    # one does not
    #add_foreign_key :price_group_members, :price_groups

    add_foreign_key :price_group_members, :users

    # The Dartmouth database fails this one
    add_foreign_key :product_users, :users
    add_foreign_key :statement_rows, :order_details

    #The UIC database violates this
    add_foreign_key :statement_rows, :statements

    add_foreign_key :statements, :accounts

    # The UIC db has one row that violates this
    add_foreign_key :user_roles, :facilities

    add_foreign_key :user_roles, :users

    # this is already null: false in the dartmouth database
    # it also fails a lot of tests 
    # change_column :journal_rows, :order_detail_id, :integer, null: false
  end
end
