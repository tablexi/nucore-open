class OrderSearchController < ApplicationController

  customer_tab :all
  before_filter :authenticate_user!
  before_filter :check_acting_as

  def index
    @order_details = GlobalSearch::OrderSearcher.new(current_user).search(params[:search])
    @other_results = GlobalSearch::StatementSearcher.new(current_user).search(params[:search])
  end

end
