# frozen_string_literal: true

class AddOrderNotificationRecipientToFacility < ActiveRecord::Migration

  def change
    add_column :facilities, :order_notification_recipient, :string, null: true
  end

end
