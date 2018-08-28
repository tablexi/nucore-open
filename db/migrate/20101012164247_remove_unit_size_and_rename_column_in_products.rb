# frozen_string_literal: true

class RemoveUnitSizeAndRenameColumnInProducts < ActiveRecord::Migration

  def self.up
    remove_column :products, :unit_size
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
