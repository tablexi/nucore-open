# frozen_string_literal: true

class PurchaseNotifierPreview < ActionMailer::Preview

  def product_order_notification
    order_detail = OrderDetail.last
    recipient = User.last
    PurchaseNotifier.product_order_notification(
      order_detail,
      recipient,
    )
  end

  def order_notification
    order = Order.last
    recipient = User.last
    PurchaseNotifier.order_notification(
      order,
      recipient,
    )
  end

end
