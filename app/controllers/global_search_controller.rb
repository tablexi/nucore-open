class GlobalSearchController < ApplicationController

  customer_tab :all

  def self.searcher_classes
    @searcher_classes ||=
      [
        GlobalSearch::OrderSearcher,
        GlobalSearch::StatementSearcher,
        GlobalSearch::ProductSearcher,
      ]
  end

  def index
    @searchers = if session_user.nil? || session_user != acting_user
                   # if user is not logged in, or if ordering on behalf, only product searching is available
                   [GlobalSearch::ProductSearcher.new(acting_user, current_facility, params[:search])]
                 else
                   self.class.searcher_classes.map do |searcher_class|
                     searcher_class.new(acting_user, current_facility, params[:search])
                   end
                 end
  end

end
