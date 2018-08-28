# frozen_string_literal: true

class ChangeScheduleRuleToBelongToProduct < ActiveRecord::Migration

  def up
    # MySQL 5.6+ will rename the foreign key with the column, but Mariadb 5.5
    # (which Dartmouth uses) triggers contraint validation errors.
    remove_foreign_key :schedule_rules, :instruments
    rename_column :schedule_rules, :instrument_id, :product_id
    add_foreign_key :schedule_rules, :products
  end

  def down
    remove_foreign_key :schedule_rules, :products
    rename_column :schedule_rules, :product_id, :instrument_id
    add_foreign_key :schedule_rules, :products, column: :instrument_id
  end

end
