module SplitAccounts

  class SplitAccountAbility < Ability

    def initialize(user, resource, controller)
      super
      cannot :manage, SplitAccounts::SplitAccount unless user.administrator?
    end

  end

end
