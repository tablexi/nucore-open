class JournalRowsAllowNullAccount < ActiveRecord::Migration
  def self.up
    change_column :journal_rows, :account, :string, :limit => 5, :null => true
  end

  def self.down
    change_column :journal_rows, :account, :string, :limit => 5, :null => false
  end
end
