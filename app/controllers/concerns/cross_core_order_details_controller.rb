# frozen_string_literal: true

module CrossCoreOrderDetailsController

  extend ActiveSupport::Concern

  def show_cross_core
    @lookup_hash = cross_core_lookup_hash

    order_details = cross_core_order_details

    @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: { date_range_field: "ordered_at", allowed_date_fields: ["ordered_at"] })
    searchers = [
      TransactionSearch::ProductSearcher,
      TransactionSearch::OrderedForSearcher,
      TransactionSearch::OrderStatusSearcher,
      TransactionSearch::DateRangeSearcher,
    ]

    @search = TransactionSearch::Searcher.new(*searchers).search(order_details, @search_form)
    @order_details = @search.order_details.includes(:order_status).reorder(sort_clause)

    respond_to do |format|
      format.html { @order_details = @order_details.paginate(page: params[:page]) }
    end
  end

  private

  def cross_core_order_details
    raise NotImplementedError
  end

  def cross_core_lookup_hash
    {
      "facility" => "facilities.name",
      "order_number" => ["order_details.order_id", "order_details.id"],
      "ordered_at" => "order_details.ordered_at",
      "status" => "order_statuses.name",
    }
  end

  # We want to allow different tabs that use different data structure to sort using the SortableColumnController concern.
  def sort_lookup_hash
    @lookup_hash
  end

end
