module SecureRooms

  module AccessRules

    class BaseRule

      def self.call(user, card_reader, accounts, selected)
        conditions_verdict = condition(user, card_reader, accounts, selected)
        conditions_verdict ? Verdict.new(conditions_verdict) : Verdict.new(:pass)
      end

      def self.condition(_user, _card_reader, _accounts, _selected)
        raise NotImplementedError
      end

    end

  end

end
