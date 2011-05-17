class InstrumentPricePolicy < PricePolicy
  @@intervals = [1, 5, 10, 15, 30, 60]

  belongs_to :instrument, :class_name => 'Product', :foreign_key => :instrument_id

  validates_numericality_of :minimum_cost, :usage_rate, :reservation_rate, :overage_rate, :usage_subsidy, :overage_subsidy, :reservation_subsidy, :cancellation_cost, :allow_nil => true, :greater_than_or_equal_to => 0
  validates_inclusion_of :usage_mins, :reservation_mins, :overage_mins, :in => @@intervals, :unless => :restrict_purchase
  validates_presence_of :usage_rate, :unless => lambda { |o| o.usage_subsidy.nil? || o.restrict_purchase?}
  validates_presence_of :reservation_rate, :unless => lambda { |o| o.reservation_subsidy.nil? || o.restrict_purchase?}
  validate :has_usage_or_reservation_rate?, :unless => :restrict_purchase
  validate :subsidy_less_than_rate?, :unless => :restrict_purchase

  named_scope :current,  lambda { |instrument|             { :conditions => ['start_date = ? AND instrument_id = ?', self.current_date(instrument, true), instrument.id] } }
  named_scope :next,     lambda { |instrument|             { :conditions => ['start_date = ? AND instrument_id = ?', self.next_date(instrument, true), instrument.id] } }
  named_scope :for_date, lambda { |instrument, start_date| { :conditions => ['start_date = ? AND instrument_id = ?', start_date.to_datetime, instrument.id] } }

  before_save do |o|
    o.usage_subsidy       = 0 if o.usage_subsidy.nil?       && !o.usage_rate.nil?
    o.reservation_subsidy = 0 if o.reservation_subsidy.nil? && !o.reservation_rate.nil?
    o.overage_subsidy     = 0 if o.overage_subsidy.nil?     && !o.overage_rate.nil?
  end

  def has_usage_or_reservation_rate?
    errors.add_to_base("You must enter a reservation rate or usage rate for all price groups") if usage_rate.nil? && reservation_rate.nil?
  end
  
  def self.current_date(instrument, with_time=false)
    ipp = instrument.instrument_price_policies.find(:first, :conditions => ['start_date <= ? AND expire_date > ?', Time.zone.now, Time.zone.now], :order => 'start_date DESC')
    ipp.nil? ? nil : with_time ? ipp.start_date.to_datetime : ipp.start_date.to_date
  end

  def self.next_date(instrument, with_time=false)
    ipp = instrument.instrument_price_policies.find(:first, :conditions => ['start_date > ?', Time.zone.now], :order => 'start_date')
    ipp.nil? ? nil : with_time ? ipp.start_date.to_datetime : ipp.start_date.to_date
  end

  def self.next_dates(instrument)
    ipps = instrument.instrument_price_policies.find(:all, :conditions => ['start_date > ?', Time.zone.now], :order => 'start_date', :select => 'DISTINCT(start_date) AS start_date')
    start_dates = ipps.collect {|ipp| ipp.start_date.to_date}
  end

  def self.intervals
    @@intervals
  end

  def reservation_window
    pgp=PriceGroupProduct.find_by_price_group_id_and_product_id(price_group.id, instrument.id)
    return pgp ? pgp.reservation_window : 0
  end

  def product
    return instrument
  end

  def restrict_purchase=(state)
    price_group_product=super

    if price_group_product and (!state or state == 0)
      price_group_product.reservation_window=PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
      price_group_product.save!
    end
  end

  def subsidy_less_than_rate?
    if (reservation_subsidy && reservation_rate)
      errors.add("reservation_subsidy", "cannot be greater than the Reservation cost") if (reservation_subsidy > reservation_rate)
    end
    if (usage_subsidy && usage_rate)
      errors.add("usage_subsidy", "cannot be greater than the Usage cost") if (usage_subsidy > usage_rate)
    end
    if (overage_subsidy && overage_rate)
      errors.add("overage_subsidy", "cannot be greater than the Overage cost") if (overage_subsidy > overage_rate)
    end
  end

  def estimate_cost_and_subsidy (start_at, end_at)
    return nil if restrict_purchase? || start_at.to_date > Date.today + reservation_window.days || end_at <= start_at
    costs = {}

    ## the instrument is free to use
    if reservation_rate.to_f == 0 && usage_rate.to_f == 0 && overage_rate.to_f == 0
      costs[:cost]    = minimum_cost || 0
      costs[:subsidy] = 0
      return costs
    end

    duration = (end_at - start_at)/60
    discount = 0
    instrument.schedule_rules.each do |sr|
      discount += sr.percent_overlap(start_at, end_at) * sr.discount_percent.to_f
    end
    discount = 1 - discount/100

    costs[:cost] = ((duration/reservation_mins).ceil * reservation_rate.to_f + (duration/usage_mins).ceil * usage_rate.to_f) * discount 
    costs[:subsidy] = ((duration/reservation_mins).ceil * reservation_subsidy.to_f + (duration/usage_mins).ceil * usage_subsidy.to_f) * discount
    if (costs[:cost] - costs[:subsidy]) < minimum_cost.to_f
      costs[:cost]    = minimum_cost
      costs[:subsidy] = 0
    end
    costs
  end

  def calculate_cost_and_subsidy (reservation)
    ## TODO update cancellation costs
    ## calculate actuals for cancelled reservations
    if (reservation.canceled_at)
      if (reservation.reserve_start_at - reserve.canceled_at)/60 >= instrument.min_cancel_hours.to_i * 60
        actual_cost = cancellation_cost
        actual_subsidy = 0
        return {:cost => actual_cost, :subsidy => actual_subsidy}
      else
        ## TODO how to calculate this
        return nil
      end
    end

    ## the instrument is free to use, so no costs matter
    if reservation_rate.to_f == 0 && usage_rate.to_f == 0 && overage_rate.to_f == 0
      actual_cost = minimum_cost || 0
      actual_subsidy = 0
      return {:cost => actual_cost, :subsidy => actual_subsidy}
    end

    ## the instrument has a reservation cost only
    if (usage_rate.to_f == 0 && overage_rate.to_f == 0)
      reserve_mins = (reservation.reserve_end_at - reservation.reserve_start_at)/60
      reserve_intervals = (reserve_mins / reservation_mins).ceil
      reserve_discount = 0
      instrument.schedule_rules.each do |sr|
        reserve_discount += sr.percent_overlap(reservation.reserve_start_at, reservation.reserve_end_at) * sr.discount_percent
      end
      reserve_discount = 1 - reserve_discount/100
      actual_cost = reservation_rate * reserve_intervals * reserve_discount
      actual_subsidy  = reservation_subsidy * reserve_intervals * reserve_discount
      if actual_cost.to_f < minimum_cost.to_f
        actual_cost    = minimum_cost
        actual_subsidy = 0
      end
      return {:cost => actual_cost, :subsidy => actual_subsidy}
    end

    ## make sure actuals are entered
    return nil unless (reservation.actual_start_at && reservation.actual_end_at)

    # calculate reservation cost & subsidy
    reserve_cost = 0
    reserve_sub  = 0
    unless reservation_rate.to_f == 0
      reserve_mins = (reservation.reserve_end_at - reservation.reserve_start_at)/60
      reserve_intervals = (reserve_mins / reservation_mins).ceil
      reserve_discount = 0
      instrument.schedule_rules.each do |sr|
        reserve_discount += sr.percent_overlap(reservation.reserve_start_at, reservation.reserve_end_at) * sr.discount_percent
      end
      reserve_discount = 1 - reserve_discount/100
      reserve_cost = reservation_rate * reserve_intervals * reserve_discount
      reserve_sub  = reservation_subsidy * reserve_intervals * reserve_discount
    end

    # calculate usage cost & subsidy
    usage_cost = 0
    usage_sub  = 0
    unless usage_rate.to_f == 0
      usage_minutes   = ([reservation.actual_end_at, reservation.reserve_end_at].min - reservation.actual_start_at)/60
      usage_intervals = (usage_minutes / usage_mins).ceil
      usage_discount = 0
      instrument.schedule_rules.each do |sr|
        usage_discount += sr.percent_overlap(reservation.actual_start_at, [reservation.actual_end_at, reservation.reserve_end_at].min) * sr.discount_percent
      end
      usage_discount = 1 - usage_discount/100
      usage_cost = usage_rate * usage_intervals * usage_discount
      usage_sub  = usage_subsidy * usage_intervals * usage_discount
    end

    # calculate overage cost & subsidy
    over_cost    = 0
    over_subsidy = 0
    rate = 0
    sub  = 0
    if overage_rate.nil?
      rate = usage_rate.to_f
      sub  = usage_subsidy.to_f
    else
      rate = overage_rate.to_f
      sub  = overage_subsidy.to_f
    end
    if reservation.actual_end_at > reservation.reserve_end_at && rate > 0
      over_mins = (reservation.actual_end_at - reservation.reserve_end_at)/60
      over_intervals = (over_mins / overage_mins).ceil
      over_cost = rate * over_intervals
      over_sub  = sub * over_intervals
    end

    # calculate total cost & subsidy
    actual_cost    = reserve_cost + usage_cost + over_cost
    actual_subsidy = reserve_sub  + usage_sub  + over_subsidy
    if actual_cost - actual_subsidy < minimum_cost.to_f
      actual_cost    = minimum_cost
      actual_subsidy = 0
    end
    return {:cost => actual_cost, :subsidy => actual_subsidy}
  end
end
