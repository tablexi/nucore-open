module SplitAccounts
  module FacilityAccountsControllerExtension
    extend ActiveSupport::Concern

    def current_ability
      SplitAccounts::SplitAccountAbility.new(current_user, current_facility, self)
    end
  end
end
