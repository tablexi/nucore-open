module C2po
  module AccountTypesExtension
    def valid_account_types
      super + [CreditCardAccount, PurchaseOrderAccount]
    end
  end
end
