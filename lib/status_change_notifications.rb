# These will use the order_status_changed_to_STATUS templates

module StatusChangeNotifications
  class NotifyPurchaserHook < StatusChangeListener
    def on_status_change(order_detail, old_status, new_status)
      Notifier.order_detail_status_change(order_detail, old_status, new_status, order_detail.order.user.email).deliver
    end
  end

  class NotifyFacilityHook < StatusChangeListener
    def on_status_change(order_detail, old_status, new_status)
      Rails.logger.info("sending email to #{order_detail.product.facility.email} that #{order_detail} has moved to #{new_status}")
      Notifier.order_detail_status_change(order_detail, old_status, new_status, order_detail.product.facility.email).deliver
    end
  end
end
