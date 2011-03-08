class OrderMailer < ActionMailer::Base

  def order_receipt(order)
    recipients    order.user.email
    from          "#{NUCore.app_name} Orders <noreply>"
    subject       "#{NUCore.app_name} Order ##{order.id} Receipt"
    sent_on       Time.now
    body          :order => order
  end


  def facility_order_notification(order)
    recipients    order.facility.order_notification_email
    from          "#{NUCore.app_name} Orders <noreply>"
    subject       "#{NUCore.app_name} Order ##{order.id} Notification"
    sent_on       Time.now
    body          :order => order
  end
end
