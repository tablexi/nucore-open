module SplitAccounts

  # Includes AccountBuilder extensions for the SplitAccounts::SplitAccount
  # account type.
  module AccountBuilderExtension
    extend ActiveSupport::Concern

    # Dynamically called by `build_subclass` if the account_type is NufsAccount.
    def build_split_accounts_split_account(account, params)
      account = build_split_account_expires_at(account, params)
      account
    end


    # Sets `expires_at` for SplitAccounts::SplitAccount only.
    def build_split_account_expires_at(account, params)
      account.expires_at = Time.zone.now + 50.years
      account
    end

  end
end
