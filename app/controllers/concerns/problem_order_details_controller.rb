module ProblemOrderDetailsController

  extend ActiveSupport::Concern

  def assign_price_policies_to_problem_orders
    assign_missing_price_policies(problem_order_details.readonly(false))
    redirect_to show_problems_path
  end

  def show_problems
    order_details = problem_order_details.joins(:order)

    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search = TransactionSearch::Searcher.new(TransactionSearch::ProductSearcher,
                                              TransactionSearch::DateRangeSearcher,
                                              TransactionSearch::OrderedForSearcher).search(order_details, @search_form)
    @order_details = @search.order_details.preload(:order_status, :assigned_user).paginate(page: params[:page])
  end

  private

  def assign_missing_price_policies(order_details)
    successfully_assigned =
      PricePolicyMassAssigner.assign_price_policies(order_details)
    flash[:notice] =
      I18n.t("controllers.problem_order_details.assign_price_policies.success",
             count: successfully_assigned.count)
  end

  def problem_order_details
    raise NotImplementedError
  end

end
