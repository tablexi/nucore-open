# frozen_string_literal: true

class NotifierPreview < ActionMailer::Preview

  def review_orders
    Notifier.review_orders(
      accounts: ::NUCore::Database.sample(Account, 3),
      facility: Facility.first,
      user: User.first,
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

  def new_internal_user
    user = FactoryBot.build(:user, username: "mynetid")
    Notifier.new_user(user: user, password: user.password)
  end

  def new_external_user
    user = FactoryBot.build(:user, :external)
    Notifier.new_user(user: user, password: user.password)
  end

  def order_detail_status_changed
    order_detail = NUCore::Database.random(OrderDetail.complete)
    Notifier.order_detail_status_changed(order_detail)
  end

end
