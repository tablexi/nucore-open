class PricePolicy < ActiveRecord::Base
  include NUCore::Database::DateHelper

  belongs_to :price_group
  belongs_to :product
  has_many :order_details

  validates_presence_of :start_date, :price_group_id, :type
  validate :start_date_is_unique, :unless => lambda { |o| o.start_date.nil? }

  validates_each :expire_date do |record,attr,value|
    unless value.blank?
      start_date=record.start_date
      gen_exp_date=generate_expire_date(start_date)
      if value <= start_date || value > gen_exp_date
        record.errors.add(:expire_date, "must be after #{start_date.to_date.to_s} and before #{gen_exp_date.to_date.to_s}")
      end
    end
  end
  
  before_create :set_expire_date
  before_create :truncate_existing_policies

  def self.for_date(start_date)
    where('start_date >= ? AND start_date <= ?', start_date.beginning_of_day, start_date.end_of_day)
  end

  def self.current
    current_for_date(Time.zone.now)
  end

  def self.current_for_date(date)
    where("start_date <= :now AND expire_date > :now", {:now => date})
  end

  def self.purchaseable
    where(:can_purchase => true)
  end

  def self.upcoming
    where("start_date > :now", {:now => Time.zone.now})
  end

  def self.for_price_groups(price_groups)
    where(:price_group_id => price_groups)
  end
  
  def self.current_date(product)
    ipp = product.price_policies.find(:first, :conditions => [dateize('start_date', ' <= ? AND ') + dateize('expire_date', ' > ?'), Time.zone.now, Time.zone.now], :order => 'start_date DESC')
    ipp ? ipp.start_date.to_date : nil
  end

  def self.next_date(product)
    ipp = product.price_policies.find(:first, :conditions => [dateize('start_date', ' > ?'), Time.zone.now], :order => 'start_date')
    ipp ? ipp.start_date.to_date : nil
  end

  def self.next_dates(product)
    ipps = []

    product.price_policies.each do |pp|
      sdate=pp.start_date
      ipps << sdate.to_date if sdate > Time.zone.now && !ipps.include?(sdate)
    end

    ipps.uniq
  end

  
  def truncate_existing_policies
    logger.debug("Truncating existing policies")
    existing_policies = PricePolicy.current.where(:type => self.class.name, 
                                                  :price_group_id => price_group_id,
                                                  :product_id => product_id)
    
    existing_policies = existing_policies.where("id != ?", id) unless id.nil?
    
    existing_policies.each do |policy|
      policy.expire_date = (start_date - 1.day).end_of_day
      policy.save
    end
    
  end
  
  def product_type
    self.class.name.gsub("PricePolicy", "").downcase
  end
 
  #
  # A price estimate for a +Product+.
  # Must return { :cost => estimated_cost, :subsidy => estimated_subsidy }
  def estimate_cost_and_subsidy(*args)
    raise "subclass must implement!"
  end


  #
  # Same as #estimate_cost_and_subsidy, but with actual prices
  def calculate_cost_and_subsidy(*args)
    raise "subclass must implement!"
  end

  #
  # Returns true if this PricePolicy's +Product+ cannot be purchased
  # by this PricePolicy's +PriceGroup+, false otherwise.
  def restrict_purchase
    return false unless price_group and product
    !can_purchase?
  end

  alias_method :restrict_purchase?, :restrict_purchase


  #
  # Dis/allows the purchase of this PricePolicy's +Product+ by this
  # PricePolicy's +PriceGroup+.
  # [_state_]
  #   true or 1 if #product should not be purchaseable by #price_group
  #   false or 0 if #product should be purchaseable by #price_group
  def restrict_purchase=(state)
    case state
      when false, 0
        self.can_purchase = true
      when true, 1
        self.can_purchase = false
      else
        raise ArgumentError.new('state must be true, false, 0, or 1')
    end
  end

  
  #
  # Returns true if this +PricePolicy+ is assigned
  # to any order, false otherwise
  def assigned_to_order?
    !OrderDetail.find_all_by_price_policy_id(self.id).empty?
  end


  #
  # Returns true if #expire_date is prior to or the same
  # as today's date, false otherwise
  def expired?
    expire_date <= Time.zone.now
  end


  def start_date_is_unique
    type          = self.class.name.downcase.gsub(/pricepolicy$/, '')
    price_group   = self.price_group
    unless (product.nil? || price_group.nil?)
      if id.nil?
        pp = PricePolicy.find(:first, :conditions => ["price_group_id = ? AND product_id = ? AND start_date = ?", price_group.id, product.id, start_date])
      else
        pp = PricePolicy.find(:first, :conditions => ["price_group_id = ? AND product_id = ? AND start_date = ? AND id <> ?", price_group.id, product.id, start_date, id])
      end
      errors.add("start_date", "conflicts with an existing price rule") unless pp.nil?
    end
  end


  #
  # Given a +PricePolicy+ or +Date+ determine the next
  # appropriate expiration date.
  def self.generate_expire_date(price_policy_or_date)
    start_date = price_policy_or_date.is_a?(PricePolicy) ? price_policy_or_date.start_date : price_policy_or_date
    SettingsHelper::fiscal_year_end(start_date)
  end

  def set_expire_date
    self.expire_date=self.class.generate_expire_date(self) unless expire_date
  end

  def editable?
    !expired? && !assigned_to_order?
  end

#  def self.active(product)
#    policies = product.send("#{product.class.name.downcase}_price_policies")
#    max      = nil
#    policies.each { |p|
#      max = p if p.start_date <= Time.zone.now && (max.nil? || p.start_date > max.start_date)
#    }
#    max
#  end?

end
