class PurchaseOrderAccount < Account
  belongs_to :facility

  validates_presence_of   :account_number

  def to_s
    string = "#{description} (#{account_number})"
    if facility
      string += " - #{facility.name}"
    end
    string
  end

  def self.need_reconciling(facility)
    account_ids = OrderDetail.find(:all,
                       :joins      => [:order, :account],
                       :conditions => [ 'orders.facility_id = ? AND accounts.type = ? AND order_details.state = ? AND statement_id IS NOT NULL', facility.id, model_name, 'complete'],
                       :select     => 'DISTINCT(order_details.account_id) AS account_id')
    find(account_ids.collect{|a| a.account_id})
  end
end
