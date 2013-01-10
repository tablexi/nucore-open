class Instrument < Product
  include Instruments::RelaySupport
  
  # Associations
  # -------
  
  has_many :schedule_rules
  has_many :instrument_price_policies, :foreign_key => 'product_id'
  has_many :reservations, :foreign_key => 'product_id'
  has_many :product_access_groups, :foreign_key => 'product_id'

  attr_writer :control_mechanism

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

  def active_reservations
    self.reservations.active
  end

  def first_available_hour
    min = 23
    schedule_rules.each { |r|
      min = r.start_hour if r.start_hour < min
    }
    min
  end
  
  def last_available_hour
    max = 0
    schedule_rules.each { |r|
      hour = r.end_min == 0 ? r.end_hour - 1 : r.end_hour
      max  = hour if hour > max
    }
    max
  end


  # calculate the last possible reservation date based on all current price policies associated with this instrument
  def last_reserve_date
    (Time.zone.now.to_date + max_reservation_window.days).to_date
  end

  def max_reservation_window
    days = price_group_products.collect{|pgp| pgp.reservation_window }.max.to_i
  end

  # find the next available reservation based on schedule rules and existing reservations
  def next_available_reservation(after = Time.zone.now, not_a_conflict=nil)
    reservation = nil
    day_of_week = after.wday
    0.upto(6) do |i|
      day_of_week = (day_of_week+i) % 6
      # find rules for day of week, sort by start hour
      rules = self.schedule_rules.select { |r| r.send("on_#{Date::ABBR_DAYNAMES[day_of_week].downcase}".to_sym) }.sort_by{ |r| r.start_hour }
      rules.each do |rule|
        # build rule start and end times
        tstart = Time.zone.local(after.year, after.month, after.day, rule.start_hour, rule.start_min, 0)
        tend   = Time.zone.local(after.year, after.month, after.day, rule.end_hour, rule.end_min, 0)
        # we can't start before tstart
        after  = tstart if after < tstart
        # check for conflicts with rule interval/duration time
        if (after.min % rule.duration_mins.to_i) != 0
          # adjust to next interval
          after += (rule.duration_mins.to_i - (after.min % rule.duration_mins.to_i)).minutes
        end
        while (after < tend)
          duration = self.min_reserve_mins.to_i < 15 ? 15.minutes : self.min_reserve_mins.to_i.minutes
          # build reservation
          reservation = self.reservations.new(:reserve_start_at => after, :reserve_end_at => after+duration)
          # check for conflicts with an existing reservation
          conflict=reservation.conflicting_reservation
          return reservation if conflict.nil? || not_a_conflict == conflict
          # we have a conflict, reset reservation and increment after by the rule's interval/duration time
          reservation = nil
          # after += self.min_reserve_mins.to_i.minutes
          after += duration
        end
      end
      # advance to start of next day
      after = after.end_of_day+1.second
    end
    reservation
  end

  def can_purchase? (group_ids = nil)
    if schedule_rules.empty?
      false
    else
      super
    end
  end
  
  def restriction_levels_for(user)
    product_access_groups.joins(:product_users).where(:product_users => {:user_id => user.id})
  end

  def set_default_pricing
    PriceGroup.globals.all.each do |pg|
      PriceGroupProduct.create!(:product => self, :price_group => pg, :reservation_window => PriceGroupProduct::DEFAULT_RESERVATION_WINDOW)
    end
  end
  
  def available_schedule_rules(user)
    if requires_approval?
      self.schedule_rules.available_to_user user
    else
      self.schedule_rules
    end
  end

end
