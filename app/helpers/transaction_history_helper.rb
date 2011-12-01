module TransactionHistoryHelper
  def single_account?
    return false unless @accounts
    @accounts.size == 1
  end
  
  def single_facility?
    return false unless @facilities
    @facilities.size == 1
  end
  
  def row_class(order_detail)
    needs_reconcile_warning?(order_detail) ? 'reconcile-warning' : ''
    # if @warning_method
      # @warning_method.call(self, order_detail) ? 'reconcile-warning' : ''
    # else
      # ''
    # end
  end
  
end
