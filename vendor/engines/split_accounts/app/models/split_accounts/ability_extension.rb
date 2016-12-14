module SplitAccounts

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      ability.cannot :create, SplitAccounts::SplitAccount unless user.administrator?

      if user.account_manager? && resource == Facility.cross_facility
        ability.can [:suspend, :unsuspend], SplitAccounts::SplitAccount
      end
    end

  end

end
