class C2poAccountValidator < FacilityAccountValidator

  def valid?
    return false if account.is_a?(PurchaseOrderAccount) && !facility.accepts_po?
    return false if account.is_a?(CreditCardAccount) && !facility.accepts_cc?
    true
  end

end
