class CreateAlerts < ActiveRecord::Migration

  def change
    create_table :secure_rooms_alerts do |t|
      t.text :additional_data
      t.string :class_code
      t.string :event_code
      t.string :event_description
      t.string :mac_address
      t.string :message_id
      t.datetime :message_time
      t.string :message_type
      t.string :priority
      t.string :task_code
      t.string :task_description

      t.timestamps null: false
    end
  end

end
