class AccountNotifier

  def notify_accounts(account_ids_to_notify)
    notifications_hash(account_ids_to_notify).each do |user_id, account_ids|
      Notifier.review_orders(user_id: user_id, account_ids: account_ids).deliver_now
    end
  end

  private

  # This builds a Hash of account_id Arrays, keyed by user_id.
  # The user_ids are the administrators (owners and business administrators)
  # of the given accounts.
  def notifications_hash(account_ids_to_notify)
    account_ids_to_notify.each_with_object({}) do |account_id, notifications|
      Account.find(account_id).administrators.each do |administrator|
        notifications[administrator.id] ||= []
        notifications[administrator.id] << account_id
      end
    end
  end

end
