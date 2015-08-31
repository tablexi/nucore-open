class NotificationSender
  attr_reader :errors, :current_facility, :account_ids_to_notify

  def initialize(current_facility, order_detail_ids)
    @current_facility = current_facility
    @order_detail_ids = order_detail_ids
  end

  def perform
    @account_ids_to_notify = Set.new
    @orders_notified = []
    @errors = []

    OrderDetail.transaction do
      order_details_not_found = @order_detail_ids.map(&:to_i) - order_details.pluck(:id)

      order_details_not_found.each do |order_detail_id|
        @errors << I18n.t('controllers.facility_notifications.send_notifications.order_error', :order_detail_id => order_detail_id)
      end

      if Settings.billing.review_period > 0
        order_details.each do |od|
          @account_ids_to_notify << [od.account_id, od.product.facility_id]
        end
      end
      order_details.update_all(reviewed_at: reviewed_at)

      notify_accounts

      raise ActiveRecord::Rollback if @errors.any?
    end

    @errors.none?
  end

  def account_ids_notified
    @account_ids_to_notify.map(&:first)
  end

  def accounts_notified
    Account.find(account_ids_notified)
  end

  def accounts_notified_size
    account_ids_to_notify.count
  end

  def order_details
    return @order_details if @order_details

    @order_details = OrderDetail.for_facility(current_facility)
      .need_notification
      .where(id: @order_detail_ids)
      .readonly(false)
      .includes(:product, :order, :price_policy, :reservation)
  end

  private

  def account
    Account.find(@accounts_to_notify.map(&:first)).map(&:account_list_item)
  end

  def reviewed_at
    @reviewed_at ||= Time.zone.now + Settings.billing.review_period
  end

  class AccountNotifier
    def notify_accounts(accounts_to_notify)
      accounts_to_notify.each do |account_id, facility_id|
        account = Account.find(account_id)
        account.notify_users.each do |u|
          Notifier.review_orders(user_id: u.id, facility_id: facility_id, account_id: account_id).deliver
        end
      end
    end
  end

  def notify_accounts
    AccountNotifier.new.delay.notify_accounts(@account_ids_to_notify)
  end

end
