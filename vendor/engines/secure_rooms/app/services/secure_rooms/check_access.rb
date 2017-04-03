module SecureRooms

  class CheckAccess

    DEFAULT_RULES = [
      AccessRules::OperatorRule,
      AccessRules::SelectedAccountRule,
      AccessRules::MultipleAccountsRule,
      AccessRules::DefaultRestrictionRule,
    ].freeze

    def initialize(rules = DEFAULT_RULES)
      @rules = rules
    end

    def authorize(user, card_reader, accounts = [], selected = nil)
      answer = @rules.each do |rule|
        result = rule.call(user, card_reader, accounts, selected)
        break result unless result.pass?
      end
    end

  end

end
