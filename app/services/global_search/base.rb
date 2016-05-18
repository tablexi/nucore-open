module GlobalSearch

  class Base

    attr_reader :facility, :query, :user

    def initialize(user = nil, facility = nil, query = nil)
      @user = user
      @facility = facility
      @query = query.to_s.strip
    end

    def results
      @results ||= execute_search_query
    end

  end

end
