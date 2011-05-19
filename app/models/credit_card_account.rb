class CreditCardAccount < Account
  attr_readonly :account_number
  before_validation :setup_false_credit_card_number
  
  validates_presence_of :name_on_card
  validates_numericality_of :expiration_month, :only_integer => true, :greater_than => 0, :less_than => 13
  validate :expiration_year_in_future

  def expiration_year_in_future
    if expiration_year.nil? || expiration_year < Time.zone.now.year || expiration_year > Time.zone.now.year + 20
      self.errors.add(:expiration_year, "must be between #{Time.zone.now.year} and #{Time.zone.now.year + 20}")
    end
  end

  def self.need_reconciling(facility)
    account_ids = OrderDetail.find(:all,
                       :joins      => [:order, :account],
                       :conditions => [ 'orders.facility_id = ? AND accounts.type = ? AND order_details.state = ? AND statement_id IS NOT NULL', facility.id, model_name, 'complete'],
                       :select     => 'DISTINCT(order_details.account_id) AS account_id')
    find(account_ids.collect{|a| a.account_id})
  end

  protected

  def setup_false_credit_card_number
    self.account_number = "xxxx-xxxx-xxxx-xxxx"
  end
end
