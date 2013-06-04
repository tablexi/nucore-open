module C2po
  module FacilityExtension
    extend ActiveSupport::Concern

    def can_pay_with_account?(account)
      return false if account.is_a?(PurchaseOrderAccount) && !accepts_po?
      return false if account.is_a?(CreditCardAccount) && !accepts_cc?
      true
    end
  end
end
