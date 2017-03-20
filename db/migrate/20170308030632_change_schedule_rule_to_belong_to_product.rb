class ChangeScheduleRuleToBelongToProduct < ActiveRecord::Migration
  def change
    rename_column :schedule_rules, :instrument_id, :product_id
  end
end
