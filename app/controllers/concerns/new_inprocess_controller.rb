module NewInprocessController

  include OrderDetailsCsvExport

  def index
    order_details = new_or_in_process_orders.joins(:order)

    @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: { date_range_field: "ordered_at" })
    @search = TransactionSearch::Searcher.new(TransactionSearch::ProductSearcher,
                                              TransactionSearch::DateRangeSearcher,
                                              TransactionSearch::OrderedForSearcher).search(order_details, @search_form)
    @order_details = @search.order_details
                            .includes(:order_status)
                            .joins("left outer join users AS assigned_users on assigned_users.id = order_details.assigned_user_id")
                            .reorder(sort_clause)

    respond_to do |format|
      format.html { @order_details = @order_details.paginate(page: params[:page]) }
      format.csv { handle_csv_search }
    end
  end

  private

  def new_or_in_process_orders
    raise NotImplementedError
  end

end
