class CreateLogEvents < ActiveRecord::Migration
  def change
    create_table :log_events do |t|
      t.references :loggable, polymorphic: true
      t.string :event_type
      t.references :user, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
  end
end
