# frozen_string_literal: true

module CrossCoreOrderDetailsController

  extend ActiveSupport::Concern

  def show_cross_core
    order_details = cross_core_order_details

    @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: { date_range_field: "ordered_at", allowed_date_fields: ["ordered_at"] })
    searchers = [
      TransactionSearch::ProductSearcher,
      TransactionSearch::OrderedForSearcher,
      TransactionSearch::OrderStatusSearcher,
      TransactionSearch::DateRangeSearcher,
    ]

    @search = TransactionSearch::Searcher.new(*searchers).search(order_details, @search_form)
    @order_details = @search.order_details.preload(:order_status, :assigned_user)

    respond_to do |format|
      format.html { @order_details = @order_details.paginate(page: params[:page]) }
    end
  end

  private

  def cross_core_order_details
    project_ids = current_facility.order_details.joins(:order).pluck(:cross_core_project_id).compact.uniq

    OrderDetail.joins(:order).where(orders: { cross_core_project_id: project_ids })
  end
end
