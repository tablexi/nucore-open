class GlobalSearchController < ApplicationController

  customer_tab :all
  before_filter :authenticate_user!
  before_filter :check_acting_as

  def self.searcher_classes
    @searcher_classes ||=
      [
        GlobalSearch::OrderSearcher,
        GlobalSearch::StatementSearcher,
      ]
  end

  def index
    @searchers = self.class.searcher_classes.map do |searcher_class|
      searcher_class.new(current_user, current_facility, params[:search])
    end
  end

end
