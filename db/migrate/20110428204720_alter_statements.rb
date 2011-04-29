class AlterStatements < ActiveRecord::Migration
  def self.up
    change_table :statements do |t|
      t.column :finalized_at, :datetime
    end
  end

  def self.down
    change_table :statements do |t|
      t.remove :finalized_at
    end
  end
end
