module TransactionHistoryHelper
  def single_account?
    return false unless @accounts
    @accounts.size == 1
  end
  
  def single_facility?
    return false unless @facilities
    @facilities.size == 1
  end
end
