class ItemPricePolicy < PricePolicy
  belongs_to :item, :class_name => 'Product', :foreign_key => :item_id

  validates_numericality_of :unit_cost, :unless => :restrict_purchase
  validate :subsidy_less_than_rate?, :unless => lambda { |pp| pp.unit_cost.nil? || pp.unit_subsidy.nil? }

  named_scope :current,  lambda { |item|             { :conditions => ['TRUNC(start_date) = ? AND item_id = ?', self.current_date(item, true), item.id] } }
  named_scope :next,     lambda { |item|             { :conditions => ['TRUNC(start_date) = ? AND item_id = ?', self.next_date(item, true), item.id] } }
  named_scope :for_date, lambda { |item, start_date| { :conditions => ['TRUNC(start_date) = ? AND item_id = ?', start_date, item.id] } }

  before_save { |o| o.unit_subsidy = 0 if o.unit_subsidy.nil? && !o.unit_cost.nil? }

  def self.current_date(item, with_time=false)
    ipp = item.item_price_policies.find(:first, :conditions => ['TRUNC(start_date) <= ? AND TRUNC(expire_date) > ?', Time.zone.now, Time.zone.now], :order => 'start_date DESC')
    ipp.nil? ? nil : with_time ? ipp.start_date.to_datetime : ipp.start_date.to_date
  end

  def self.next_date(item, with_time=false)
    ipp = nil
    item.item_price_policies.sort{|p1,p2| p1.start_date <=> p2.start_date}.each{|pp| ipp=pp and break if pp.start_date > Time.zone.now}
    ipp.nil? ? nil : with_time ? ipp.start_date.to_datetime : ipp.start_date.to_date
  end

  def self.next_dates(item)
    ipps = []

    item.item_price_policies.each do |pp|
      sdate=pp.start_date
      ipps << sdate.to_date if sdate > Time.zone.now && !ipps.include?(sdate)
    end

    ipps.uniq
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
    return item
  end
end
