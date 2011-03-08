class RemoveUnitSizeAndRenameColumnInProducts < ActiveRecord::Migration
  def self.up
    remove_column :products, :unit_size
    rename_column :products, :min_cancel_mins, :min_cancel_hours
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
