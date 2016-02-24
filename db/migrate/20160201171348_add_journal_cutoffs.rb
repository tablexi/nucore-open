class AddJournalCutoffs < ActiveRecord::Migration

  def change
    create_table :journal_cutoff_dates do |t|
      t.datetime :cutoff_date
      t.timestamps
    end
  end

end
