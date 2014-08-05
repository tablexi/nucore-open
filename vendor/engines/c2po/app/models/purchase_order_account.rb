class PurchaseOrderAccount < Account
  include AffiliateAccount
  include ReconcilableAccount

  belongs_to :facility

  validates_presence_of   :account_number


  def to_s(with_owner = false)
    desc = super
    desc += " / #{facility.name}" if facility
    desc
  end
end
