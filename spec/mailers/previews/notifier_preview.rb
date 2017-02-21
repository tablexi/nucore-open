class NotifierPreview < ActionMailer::Preview

  def review_orders
    Notifier.review_orders(
      account_ids: Account.limit(3).pluck(:id),
      facility: Facility.first,
      user_id: User.first.id,
    )
  end

  def statement
    statement = Statement.first
    Notifier.statement(
      user: User.first,
      facility: statement.facility,
      account: statement.account,
      statement: statement,
    )
  end

end
