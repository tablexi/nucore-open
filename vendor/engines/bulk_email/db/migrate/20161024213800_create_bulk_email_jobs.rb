class CreateBulkEmailJobs < ActiveRecord::Migration

  def change
    create_table :bulk_email_jobs do |t|
      t.string :sender, null: false
      t.string :subject, null: false
      t.text :recipients, null: false
      t.text :search_criteria, null: false
      t.timestamps null: false
    end
  end

end
