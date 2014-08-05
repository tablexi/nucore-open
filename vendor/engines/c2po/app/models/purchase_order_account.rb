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
    where(id: OrderDetail
      .joins(:order, :account)
      .select('DISTINCT(order_details.account_id) AS account_id')
      .where('orders.facility_id' => facility.id)
      .where('accounts.type' => model_name)
      .where('order_details.state' => 'complete')
      .where('statement_id IS NOT NULL')
      .pluck(:account_id))
  end
end
