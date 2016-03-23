module SplitAccounts

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, _resource)
      ability.cannot :create, SplitAccounts::SplitAccount unless user.administrator?
    end

  end

end
