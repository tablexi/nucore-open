class NotifierPreview < ActionMailer::Preview

  def review_orders
    Notifier.review_orders(
      account_ids: Account.limit(3).pluck(:id),
      facility_id: Facility.first.id,
      user_id: User.first.id,
    )
  end

end
