module SplitAccounts
  class SplitAccountAbility < Ability

    def initialize(user, resource, controller)
      super
      unless user.administrator?
        cannot :manage, SplitAccounts::SplitAccount
      end
    end
  end
end
