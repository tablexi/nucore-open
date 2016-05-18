module GlobalSearch

  class StatementSearcher < Base

    def template
      "statements"
    end

    private

    def execute_search_query
      return [] unless Account.config.statements_enabled? && query.present?
      statement = Statement.find_by_invoice_number(query.sub(/\A#/, ""))
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

  end

end
