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
      find_missing_order_details

      raise ActiveRecord::Rollback if @errors.any?

      find_accounts_to_notify if SettingsHelper.has_review_period?
      mark_order_details_as_reviewed
      notify_accounts
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

  private

  def find_missing_order_details
    ids = order_detail_groups.flat_map { |order_details| order_details.pluck(:id) }
    order_details_not_found = @order_detail_ids.map(&:to_i) - ids

    order_details_not_found.each do |order_detail_id|
      @errors << I18n.t('controllers.facility_notifications.send_notifications.order_error', :order_detail_id => order_detail_id)
    end
  end

  def find_accounts_to_notify
    order_detail_groups.each do |order_details|
      # TODO Poor man's multi-item `pluck`
      ActiveRecord::Base.connection.select_all(order_details.select(["order_details.account_id", "products.facility_id"])).each do |od|
        @account_ids_to_notify << [od["account_id"], od["facility_id"]]
      end
    end
  end

  def mark_order_details_as_reviewed
    order_detail_groups.each do |order_details|
      order_details.update_all(reviewed_at: reviewed_at)
    end
  end

  def order_detail_groups
    return @order_detail_groups if @order_detail_groups

    # An array of AR relations because Oracle doesn't allow WHERE IN (...) to
    # have more than 1000 items.
    enumerator = NUCore::Database.oracle? ? @order_detail_ids.each_slice(1000) : [@order_detail_ids]

    @order_detail_groups = enumerator.map do |od_slice|
      OrderDetail.for_facility(current_facility)
        .need_notification
        .where(id: od_slice)
        .includes(:product, :order, :price_policy, :reservation)
    end
  end

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
