module SplitAccounts

  class SplitAccountAbility < Ability

    def initialize(user, resource, controller)
      super
      cannot :create, SplitAccounts::SplitAccount unless user.administrator?
    end

  end

end
