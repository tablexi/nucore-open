class GlobalSearchController < ApplicationController

  customer_tab :all
  before_filter :authenticate_user!
  before_filter :check_acting_as

  def index
    @results = {
      order_details: GlobalSearch::OrderSearcher.new(current_user).search(params[:search]),
      statements: search_statements,
    }
  end

  private

  def search_statements
    if Account.config.statements_enabled?
      GlobalSearch::StatementSearcher.new(current_user).search(params[:search])
    else
      []
    end
  end

end
