class ServicePricePolicy < PricePolicy
  belongs_to :service, :class_name => 'Product', :foreign_key => :service_id

  validates_numericality_of :unit_cost, :unless => :restrict_purchase
  validate :subsidy_less_than_rate?, :unless => lambda { |pp| pp.unit_cost.nil? || pp.unit_subsidy.nil? }

  named_scope :current,  lambda { |service|             { :conditions => ['TRUNC(start_date) = ? AND service_id = ?', self.current_date(service), service.id] } }
  named_scope :next,     lambda { |service|             { :conditions => ['TRUNC(start_date) = ? AND service_id = ?', self.next_date(service), service.id] } }
  named_scope :for_date, lambda { |service, start_date| { :conditions => ['TRUNC(start_date) = ? AND service_id = ?', start_date.to_date, service.id] } }

  before_save { |o| o.unit_subsidy = 0 if o.unit_subsidy.nil? && !o.unit_cost.nil? }

  def self.current_date(service)
    ipp = service.service_price_policies.find(:first, :conditions => ['TRUNC(start_date) <= ? AND TRUNC(expire_date) > ?', Time.zone.now, Time.zone.now], :order => 'start_date DESC')
    ipp ? ipp.start_date.to_date : nil
  end

  def self.next_date(service)
    ipp = service.service_price_policies.find(:first, :conditions => ['TRUNC(start_date) > ?', Time.zone.now], :order => 'start_date')
    ipp ? ipp.start_date.to_date : nil
  end

  def self.next_dates(service)
    ipps = service.service_price_policies.find(:all, :conditions => ['TRUNC(start_date) > ?', Time.zone.now], :order => 'start_date', :select => 'DISTINCT(start_date) AS start_date')
    start_dates = ipps.collect {|ipp| ipp.start_date.to_date}
  end

  def subsidy_less_than_rate?
    errors.add("unit_subsidy", "cannot be greater than the Unit cost") if (unit_subsidy > unit_cost)
  end

  def calculate_cost_and_subsidy (qty = 1)
    estimate_cost_and_subsidy(qty)
  end

  def estimate_cost_and_subsidy(qty = 1)
    return nil if restrict_purchase?
    costs = {}
    costs[:cost]    = unit_cost * qty
    costs[:subsidy] = unit_subsidy * qty
    costs
  end

  def unit_total
    unit_cost - unit_subsidy
  end

  def product
    return service
  end
end
