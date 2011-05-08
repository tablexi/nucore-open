class AddJournalDateToJournals < ActiveRecord::Migration
  def self.up
    add_column :journals, :journal_date, :date, :null => true, :after => :facility_id
    execute 'UPDATE journals SET journal_date = created_at'
    change_column :journals, :journal_date, :date, :null => false
  end

  def self.down
    remove_column :journals, :journal_date
  end
end
