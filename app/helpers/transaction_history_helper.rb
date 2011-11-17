module TransactionHistoryHelper
  def transaction_search_submit_path(account)
    if (account)
      account_transaction_history_path(account)
    else
      transaction_history_path
    end
  end
  
  def single_account?
    @accounts.size == 1
    #!@search_fields[:accounts].nil? and @search_fields[:accounts].size == 1
  end
  
  def single_facility?
    @facilities.size == 1
    #!@search_fields[:facilities].nil? and @search_fields[:facilities].size == 1
  end
end
