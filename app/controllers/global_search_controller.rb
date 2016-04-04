class GlobalSearchController < ApplicationController

  customer_tab :all
  before_filter :authenticate_user!
  before_filter :check_acting_as

  def index
    @results = {
      order_details: GlobalSearch::OrderSearcher.new(current_user).search(params[:search]),
      statements: GlobalSearch::StatementSearcher.new(current_user).search(params[:search]),
    }
  end

end
