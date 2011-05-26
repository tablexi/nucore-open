class PricePolicy < ActiveRecord::Base
  include NUCore::Database::DateHelper

  belongs_to :price_group
  validates_presence_of :start_date, :price_group_id, :type
  validate :start_date_is_unique, :unless => lambda { |o| o.start_date.nil? }

  validates_each :expire_date do |record,attr,value|
    unless value.blank?
      value=value.to_date
      start_date=record.start_date.to_date
      gen_exp_date=generate_expire_date(start_date).to_date

      if value <= start_date || value > gen_exp_date
        record.errors.add(:expire_date, "must be after #{start_date.to_date.to_s} and before #{gen_exp_date.to_date.to_s}")
      end
    end
  end

  named_scope :active, lambda {{ :conditions => [ "start_date <= ?", Time.zone.now ], :order => "start_date DESC" }}


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
  # All subclasses +belong_to+ a +Product+ and have their own
  # unique accessors for that product. That association should
  # be made in this class, but it isn't. This method provides
  # general access to a subclass' product
  def product
    raise "subclass must implement!"
  end


  #
  # Returns true if this PricePolicy's +Product+ cannot be purchased
  # by this PricePolicy's +PriceGroup+, false otherwise.
  def restrict_purchase
    return false unless price_group and product
    PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id).nil?
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
        PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(price_group.id, product.id)
      when true, 1
        pgp=PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, product.id)
        pgp.destroy if pgp
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
    expire_date.to_date <= Time.zone.now.to_date
  end


  def start_date_is_unique
    type          = self.class.name.downcase.gsub(/pricepolicy$/, '')
    product       = self.send("#{type}")
    price_group   = self.price_group
    unless (product.nil? || price_group.nil?)
      if id.nil?
        pp = PricePolicy.find(:first, :conditions => ["price_group_id = ? AND #{type}_id = ? AND start_date = ?", price_group.id, product.id, start_date])
      else
        pp = PricePolicy.find(:first, :conditions => ["price_group_id = ? AND #{type}_id = ? AND start_date = ? AND id <> ?", price_group.id, product.id, start_date, id])
      end
      errors.add("start_date", "conflicts with an existing price rule") unless pp.nil?
    end
  end


  #
  # Given a +PricePolicy+ or +Date+ determine the next
  # appropriate expiration date.
  def self.generate_expire_date(price_policy_or_date)
    start_date=price_policy_or_date.is_a?(PricePolicy) ? price_policy_or_date.start_date : price_policy_or_date
    exp_date=Time.zone.parse("#{start_date.year}-8-31")
    exp_date=Time.zone.parse("#{start_date.year+1}-8-31") if start_date.to_date >= exp_date.to_date
    return exp_date
  end


  def before_create
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
