# frozen_string_literal: true

class PurchaseNotifierPreview < ActionMailer::Preview

  def product_order_notification
    order_detail = OrderDetail.purchased.last
    recipient = User.last
    PurchaseNotifier.with(
      order_detail: order_detail,
      recipient: recipient,
    ).product_order_notification
  end

  def order_notification
    order = Order.purchased.last
    recipient = User.last
    PurchaseNotifier.with(
      order: order,
      recipient: recipient,
    ).order_notification
  end

end
