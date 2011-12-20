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
  
  def product_options(products, search_fields)
    options = []
    products.each do |product|
      selected = search_fields && search_fields.include?(product.id.to_s) ? "selected = \"selected\"" : ""
      options << "<option value=\"#{product.id}\" data-facility=\"#{product.facility.id}\" #{selected}>#{product.name}</option>"
    end
    options.join("\n").html_safe
    #options_from_collection_for_select(products, "id", "name", search_fields)
  end
  
end
