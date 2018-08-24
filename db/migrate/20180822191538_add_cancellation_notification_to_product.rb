class AddCancellationNotificationToProduct < ActiveRecord::Migration[5.0]

  def change
    change_table :products do |t|
      t.text :cancellation_notification_recipients
    end
  end

end
