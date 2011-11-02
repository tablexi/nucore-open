module TransactionHistoryHelper
  def transaction_search_submit_path(account)
    if (account)
      account_transaction_history_path(account)
    else
      transaction_history_path
    end
  end
end
