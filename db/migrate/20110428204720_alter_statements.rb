class AlterStatements < ActiveRecord::Migration
  # On second thought, don't migrate the finalized_at column to statements from account_transactions

  def self.up
#    change_table :statements do |t|
#      t.column :finalized_at, :datetime
#    end
  end

  def self.down
#    change_table :statements do |t|
#      t.remove :finalized_at
#    end
  end
end
