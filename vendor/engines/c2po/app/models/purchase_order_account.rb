class PurchaseOrderAccount < Account
  include AffiliateAccount

  belongs_to :facility

  validates_presence_of   :account_number


  def to_s(with_owner = false)
    desc = super
    desc += " / #{facility.name}" if facility
    desc
  end

  def self.need_reconciling(facility)
    accounts = OrderDetail.unreconciled_accounts(facility, model_name)
    where(id: accounts.pluck(:account_id))
  end
end
