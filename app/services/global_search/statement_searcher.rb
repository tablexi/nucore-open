module GlobalSearch

  class StatementSearcher

    attr_reader :facility, :query, :user

    def initialize(user = nil, facility = nil, query = nil)
      @user = user
      @facility = facility
      @query = sanitize_search_string(query)
    end

    def results
      @results ||= execute_search_query
    end

    private

    def execute_search_query
      return [] unless Account.config.statements_enabled?
      statement = Statement.find_by_invoice_number(query)
      Array(restrict(statement))
    end

    def restrict(statement)
      return unless statement

      statement if abilities(statement).any? { |ability| ability.can? :show, statement }
    end

    # Account owners & business admins get their abilities through the account,
    # while facility staff get theirs through the facility, so we need to check
    # both.
    def abilities(statement)
      [
        Ability.new(user, statement.facility),
        Ability.new(user, statement.account),
      ]
    end

    def sanitize_search_string(search_string)
      search_string.to_s
        .strip # get rid of leading/trailing whitespace
        .sub(/\A#/, "") # remove a leading hash sign to support searching like "#123-456"
    end

  end

end
