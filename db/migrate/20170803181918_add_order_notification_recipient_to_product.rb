# frozen_string_literal: true

class AddOrderNotificationRecipientToProduct < ActiveRecord::Migration

  def change
    add_column :products, :order_notification_recipient, :string, null: true
  end

end
