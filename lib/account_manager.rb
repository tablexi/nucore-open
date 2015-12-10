# Deprecate this in favor of using either `Account` or an `AccountManager`
# service object.
class AccountManager

  def self.creatable_account_types_for_facility(facility)
    Account.config.account_types_for_facility(facility)
  end

  def self.using_statements?
    Account.config.using_statements?
  end

  def self.using_affiliates?
    Account.config.using_affiliates?
  end

  def self.multiple_account_types?
    Account.config.multiple_account_types?
  end

  def self.valid_account_types
    Account.config.account_types
  end

  module Overridable
    def valid_account_types
      Account.config.account_types
    end
  end

  include Overridable
end
