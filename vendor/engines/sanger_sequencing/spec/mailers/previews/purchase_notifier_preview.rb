class PurchaseNotifierPreview < ActionMailer::Preview

  def sanger_order_notification
    submission = Nucore::Database.random(SangerSequencing::Submission.joins(:order_detail).merge(OrderDetail.purchased))
    order_detail = submission.order_detail
    PurchaseNotifier.with(
      order_detail: order_detail.order,
      recipient: order_detail.user,
    ).order_notification
  end

end
