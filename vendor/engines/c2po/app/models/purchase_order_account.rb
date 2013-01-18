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
    account_ids = OrderDetail.joins(:order, :account).
                              select('DISTINCT(order_details.account_id) AS account_id').
                              where('orders.facility_id = ? AND accounts.type = ? AND order_details.state = ? AND statement_id IS NOT NULL', facility.id, model_name, 'complete').
                              all

    find(account_ids.collect{|a| a.account_id})
  end
end
