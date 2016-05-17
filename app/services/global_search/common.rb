module GlobalSearch

  module Common

    extend ActiveSupport::Concern

    included do
      attr_reader :facility, :query, :user
    end

    def initialize(user = nil, facility = nil, query = nil)
      @user = user
      @facility = facility
      @query = sanitize_search_string(query)
    end

    def results
      @results ||= execute_search_query
    end
  end

end
