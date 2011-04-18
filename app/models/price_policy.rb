class PricePolicy < ActiveRecord::Base

  belongs_to :price_group
  validates_presence_of :start_date, :price_group_id, :type
  validate :start_date_is_unique, :unless => lambda { |o| o.start_date.nil? }

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
        PriceGroupProduct.create!(:price_group => price_group, :product => product)
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


  def before_create
    return if expire_date
    exp_date=Date.strptime("#{start_date.year}-8-31")
    exp_date=Date.strptime("#{start_date.year+1}-8-31") if exp_date <= Time.zone.now.to_date
    self.expire_date=exp_date
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
