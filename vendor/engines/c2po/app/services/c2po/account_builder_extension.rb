module C2po

  # Includes AccountBuilder extensions for both CreditCardAccount and
  # PurchaseOrderAccount account types.
  module AccountBuilderExtension
    extend ActiveSupport::Concern

    # Dynamically called by `build_subclass` if the account_type is
    # CreditCardAccount.
    def build_credit_card_account(account, params)
      account = build_credit_card_account_expires_at(account, params)
      account
    end

    # Dynamically called by `build_subclass` if the account_type is
    # PurchaseOrderAccount.
    def build_purchase_order_account(account, params)
      account = build_purchase_order_account_expires_at(account, params)
      account
    end

    # Sets `expires_at` for CreditCardAccount only.
    def build_credit_card_account_expires_at(account, params)
      account.expires_at = Date.civil(account.expiration_year.to_i, account.expiration_month.to_i).end_of_month.end_of_day
      account
    end

    # Sets `expires_at` for PurchaseOrderAccount only.
    def build_purchase_order_account_expires_at(account, params)
      account.expires_at = account.expires_at.try(:end_of_day)
      account
    end

  end
end
