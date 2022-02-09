# frozen_string_literal: true

class NotifierPreview < ActionMailer::Preview

  def user_update
    Notifier.with(
      account: Account.first,
      created_by: User.last,
      user: User.first,
      role: AccountUser::ACCOUNT_PURCHASER,
      send_to: "bob@example.com",
    ).user_update
  end

  def review_orders
    Notifier.with(
      accounts: ::Nucore::Database.sample(Account, 3),
      facility: Facility.first,
      user: User.first,
    ).review_orders
  end

  def statement
    statement = Statement.first
    Notifier.with(
      user: User.first,
      facility: statement.facility,
      account: statement.account,
      statement: statement,
    ).statement
  end

  def new_internal_user
    user = FactoryBot.build(:user, :netid, username: "mynetid")
    Notifier.with(user: user, password: user.password).new_user
  end

  def new_external_user
    user = FactoryBot.build(:user, password: "abc123")
    Notifier.with(user: user, password: user.password).new_user
  end

  def order_detail_status_changed
    order_detail = Nucore::Database.random(OrderDetail.complete)
    Notifier.with(order_detail: order_detail).order_detail_status_changed
  end

end
