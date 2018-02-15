module NewInprocessController

  def index
    order_details = new_or_in_process_orders.joins(:order)

    @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: { date_range_field: "ordered_at" })
    @search = TransactionSearch::Searcher.new(TransactionSearch::ProductSearcher,
                                              TransactionSearch::DateRangeSearcher,
                                              TransactionSearch::OrderedForSearcher).search(order_details, @search_form, billing_context: false)
    @order_details = @search.order_details.preload(:order_status, :assigned_user).paginate(page: params[:page])
  end

  private

  def new_or_in_process_orders
    raise NotImplementedError
  end

end
