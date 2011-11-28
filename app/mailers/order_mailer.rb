class OrderMailer < ActionMailer::Base
  default :sender => "#{I18n.t :app_name} Orders <noreply>"


  def order_receipt(order)
    @order=order
    mail(:to => order.user.email, :subject => "#{I18n.t :app_name} Order ##{order.id} Receipt")
  end


  def facility_order_notification(order)
    @order=order
    mail(:to => order.facility.order_notification_email, :subject => "#{I18n.t app_name} Order ##{order.id} Notification")
  end
end
