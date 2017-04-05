module SecureRooms

  class CheckAccess

    DEFAULT_RULES = [
      AccessRules::OperatorRule,
      AccessRules::ArchivedProductRule,
      AccessRules::RequiresApprovalRule,
      AccessRules::AccountSelectionRule,
      AccessRules::DenyAllRule,
    ].freeze

    def initialize(rules = DEFAULT_RULES)
      @rules = rules
    end

    def authorize(user, card_reader, accounts = [], selected = nil)
      answer = @rules.each do |rule|
        result = rule.new(user, card_reader, accounts, selected).call
        break result unless result.pass?
      end
    end

  end

end
