module GlobalSearch

  class StatementSearcher

    def initialize(user = nil)
      @user = user
    end

    def search(query)
      statement = Statement.find_by_invoice_number(query.to_s.strip)
      Array(restrict(statement))
    end

    private

    def restrict(statement)
      return unless statement

      statement if abilities(statement).any? { |ability| ability.can? :show, statement }
    end

    # Account owners & business admins get their abilities through the account,
    # while facility staff get theirs through the facility, so we need to check
    # both.
    def abilities(statement)
      [
        Ability.new(@user, statement.facility),
        Ability.new(@user, statement.account),
      ]
    end

  end

end
