class Instrument < Product
  include Products::RelaySupport
  include Products::SchedulingSupport
  
  # Associations
  # -------
  
  has_many :instrument_price_policies, :foreign_key => 'product_id'
  has_many :product_access_groups, :foreign_key => 'product_id'

  accepts_nested_attributes_for :relay

  # Validations
  # --------
  before_validation :init_or_destroy_relay

  validates_presence_of :initial_order_status_id
  validates_presence_of :facility_account_id if SettingsHelper.feature_on? :recharge_accounts
  validates_numericality_of :min_reserve_mins, :max_reserve_mins, :auto_cancel_mins, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  
  # Callbacks
  # --------

  after_create :set_default_pricing

  # Instance methods
  # -------

  # calculate the last possible reservation date based on all current price policies associated with this instrument
  def last_reserve_date
    (Time.zone.now.to_date + max_reservation_window.days).to_date
  end

  def max_reservation_window
    days = price_group_products.collect{|pgp| pgp.reservation_window }.max.to_i
  end

  def restriction_levels_for(user)
    product_access_groups.joins(:product_users).where(:product_users => {:user_id => user.id})
  end

  def set_default_pricing
    PriceGroup.globals.all.each do |pg|
      PriceGroupProduct.create!(:product => self, :price_group => pg, :reservation_window => PriceGroupProduct::DEFAULT_RESERVATION_WINDOW)
    end
  end
  
end
