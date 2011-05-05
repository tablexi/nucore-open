class AlterStatements < ActiveRecord::Migration
  def self.up
    change_table :statements do |t|
      t.column :account_id, :integer, :null => false
    end
  end

  def self.down
    change_table :statements do |t|
      t.remove :account_id
    end
  end
end
