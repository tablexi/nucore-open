# frozen_string_literal: true

# These will use the order_status_changed_to_STATUS templates

module StatusChangeNotifications

  class NotifyPurchaserHook

    def on_status_change(order_detail, old_status, new_status)
      Notifier.delay.order_detail_status_change(order_detail, old_status, new_status, order_detail.order.user.email)
    end

  end

  class NotifyFacilityHook

    def on_status_change(order_detail, old_status, new_status)
      Notifier.delay.order_detail_status_change(order_detail, old_status, new_status, order_detail.product.email)
    end

  end

end
