require "date"
require "pp"
class Reservation < ActiveRecord::Base
  include DateHelper

  belongs_to :instrument
  belongs_to :order_detail

  validates_uniqueness_of :order_detail_id, :allow_nil => true
  validates_presence_of :instrument_id, :reserve_start_at, :reserve_end_at
  validate :does_not_conflict_with_other_reservation, :satisfies_minimum_length, :satisfies_maximum_length, :instrument_is_available_to_reserve, :in_the_future, :if => :reserve_start_at && :reserve_end_at && :reservation_changed?

  validates_each [ :actual_start_at, :actual_end_at ] do |record,attr,value|
    if value
      record.errors.add(attr.to_s,'cannot be in the future') if Time.zone.now < value
    end
  end

  validate :starts_before_ends
  #validate :in_window, :if => :has_order_detail?
  #validate minimum_cost met

  # virtual attributes
  attr_accessor     :duration_mins, :duration_value, :duration_unit,
                    :reserve_start_date, :reserve_start_hour, :reserve_start_min, :reserve_start_meridian,
                    :actual_start_date, :actual_start_hour, :actual_start_min, :actual_start_meridian,
                    :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian
  before_validation :set_reserve_start_at, :set_reserve_end_at, :set_actual_start_at, :set_actual_end_at

  scope :active, :conditions => ["reservations.canceled_at IS NULL AND (orders.state = 'purchased' OR orders.state IS NULL)"], :joins => ['LEFT JOIN order_details ON order_details.id = reservations.order_detail_id', 'LEFT JOIN orders ON orders.id = order_details.order_id']
  scope :limit,    lambda { |n| {:limit => n}}


  def self.upcoming(t=Time.zone.now)
    # If this is a named scope differences emerge between Oracle & MySQL on #reserve_end_at querying.
    # Eliminate by letting Rails filter by #reserve_end_at
    reservations=find(:all, :conditions => "reservations.canceled_at IS NULL AND (orders.state = 'purchased' OR orders.state IS NULL)", :order => 'reserve_end_at asc', :joins => ['LEFT JOIN order_details ON order_details.id = reservations.order_detail_id', 'LEFT JOIN orders ON orders.id = order_details.order_id'])
    reservations.delete_if{|r| r.reserve_end_at < t}
    reservations
  end


  def order
    order_detail.order if order_detail
  end


  def user
    order.user if order
  end


  def account
    order_detail.account if order_detail
  end


  def owner
    account.owner if account
  end


  def starts_before_ends
    if reserve_start_at && reserve_end_at
      errors.add('reserve_end_date','must be after the reservation start time') if reserve_end_at <= reserve_start_at
    end
    if actual_start_at && actual_end_at
      errors.add('actual_end_date','must be after the actual start time') if actual_end_at <= actual_start_at
    end
  end

  def set_all_split_times
    set_reserve_start_at
    set_reserve_end_at
    set_actual_start_at
    set_actual_end_at
  end

  # set set_reserve_start_at based on reserve_start_xxx virtual attributes
  def set_reserve_start_at
    return unless self.reserve_start_at.blank?
    if @reserve_start_date and @reserve_start_hour and @reserve_start_min and @reserve_start_meridian
      self.reserve_start_at = parse_usa_date(@reserve_start_date, "#{@reserve_start_hour.to_s}:#{@reserve_start_min.to_s.rjust(2, '0')} #{@reserve_start_meridian}")
    end
  end

  # set reserve_end_at based on duration_value, duration_unit virtual attribute
  def set_reserve_end_at
    return unless self.reserve_end_at.blank?
    case @duration_unit
    when 'minutes', 'minute'
      @duration_mins = @duration_value.to_i
    when 'hours', 'hour'
      @duration_mins = @duration_value.to_i * 60
    else
      @duration_mins = 0
    end
    self.reserve_end_at = self.reserve_start_at + @duration_mins.minutes
  end

  def set_actual_start_at
    return unless self.actual_start_at.blank?
    if @actual_start_date and @actual_start_hour and @actual_start_min and @actual_start_meridian
      self.actual_start_at = parse_usa_date(@actual_start_date, "#{@actual_start_hour.to_s}:#{@actual_start_min.to_s.rjust(2, '0')} #{@actual_start_meridian}")
    end
  end

  def set_actual_end_at
    return unless self.actual_end_at.blank?
    if @actual_end_date and @actual_end_hour and @actual_end_min and @actual_end_meridian
      self.actual_end_at = parse_usa_date(@actual_end_date, "#{@actual_end_hour.to_s}:#{@actual_end_min.to_s.rjust(2, '0')} #{@actual_end_meridian}")
    end
  end

  def does_not_conflict_with_other_reservation?
    conflicting_reservation.nil?
  end

  def does_not_conflict_with_other_reservation
    res=conflicting_reservation

    if res
      msg='The reservation conflicts with another reservation'
      msg += ' in your cart. Please purchase or remove it then continue.' if res.order.try(:==, order)
      errors.add(:base, msg.html_safe)
    end
  end

  #
  # Look for a reservation on the same instrument that conflicts in time with a
  # purchased, admin, or in-cart reservation. Should not check reservations that
  # are unpurchased in other user's carts.
  def conflicting_reservation
    # remove millisecond precision from time
    tstart_at = Time.zone.parse(reserve_start_at.to_s)
    tend_at   = Time.zone.parse(reserve_end_at.to_s)
    order_id  = order_detail.nil? ? 0 : order_detail.order_id

    Reservation.
    joins('LEFT JOIN order_details ON order_details.id = reservations.order_detail_id',
          'LEFT JOIN orders ON orders.id = order_details.order_id').
    where("reservations.instrument_id = ? AND
          reservations.id <> ? AND
          reservations.canceled_at IS NULL AND
          reservations.actual_end_at IS NULL AND
          (orders.state = 'purchased' OR orders.state IS NULL OR orders.id = ?) AND
          ((reserve_start_at <= ? AND reserve_end_at >= ?) OR
          (reserve_start_at >= ? AND reserve_end_at <= ?) OR
          (reserve_start_at <= ? AND reserve_end_at > ?) OR
          (reserve_start_at < ? AND reserve_end_at >= ?) OR
          (reserve_start_at = ? AND reserve_end_at = ?))",
          instrument.id, id||0, order_id, tstart_at, tend_at, tstart_at, tend_at, tstart_at, tstart_at, tend_at, tend_at, tstart_at, tend_at).first
  end

  def satisfies_minimum_length?
    diff = reserve_end_at - reserve_start_at # in seconds
    return false unless instrument.min_reserve_mins.nil? || instrument.min_reserve_mins == 0 || diff/60 >= instrument.min_reserve_mins
    true
  end

  def satisfies_minimum_length
    errors.add(:base, "The reservation is too short") unless satisfies_minimum_length?
  end

  def satisfies_maximum_length?
    diff = reserve_end_at - reserve_start_at # in seconds
    return false unless instrument.max_reserve_mins.nil? || instrument.max_reserve_mins == 0 || diff/60 <= instrument.max_reserve_mins
    true
  end

  def satisfies_maximum_length
    errors.add(:base, "The reservation is too long") unless satisfies_maximum_length?
  end

  # checks that the reservation is within the longest window for the groups the user is in
  def in_window?
    groups   = (order_detail.order.user.price_groups + order_detail.order.account.price_groups).flatten.uniq
    max_days = longest_reservation_window(groups)
    diff     = reserve_start_at.to_date - Date.today
    diff <= max_days
  end

  def in_window
    errors.add(:base, "The reservation is too far in advance") unless in_window?
  end

  def in_the_future?
    reserve_start_at > Time.zone.now
  end
  
  def in_the_future
    errors.add(:reserve_start_at, "The reservation must start at a future time") unless in_the_future?
  end

  def instrument_is_available_to_reserve
    errors.add(:base, "The reservation spans time that the instrument is unavailable for reservation") unless instrument_is_available_to_reserve?
  end

  def instrument_is_available_to_reserve? (start_at = self.reserve_start_at, end_at = self.reserve_end_at)
    mins  = (end_at - start_at)/60
    rules = instrument.schedule_rules.each

    (0..mins).each { |n|
      dt    = start_at.advance(:minutes => n)
      found = false
      rules.each { |s|
        if s.includes_datetime(dt)
          found = true
          break
        end
      }
      unless found
        return false
      end
    }
    true
  end

  def as_calendar_object(options={})
    # initialize result with defaults
    calendar_object = {
      "start"  => reserve_start_at.strftime("%a, %d %b %Y %H:%M:%S"),
      "end"    => reserve_end_at.strftime("%a, %d %b %Y %H:%M:%S"),
      "allDay" => false,
      "title"  => "Reservation",
    }

    if options[:with_details]
      if order
        overrides = {
          "admin"       => false,
          "email"        => order.user.email,
          "name"        => "#{order.user.full_name}",
          "title"       => "#{order.user.first_name}\n#{order.user.last_name}",
        }
      else
        overrides = {
          "admin"       => true,
          "title"       => "Admin\nReservation",
        }
      end

      calendar_object.merge!(overrides)
    end

    calendar_object
  end

  #
  # Virtual attributes
  #
  def reserve_start_hour
    case
    when @reserve_start_hour
      @reserve_start_hour.to_i
    when !reserve_start_at.blank?
      hour = reserve_start_at.hour.to_i % 12
      hour == 0 ? 12 : hour
    else
      nil
    end
  end

  def reserve_start_min
    case
    when @reserve_start_min
      @reserve_start_min.to_i
    when !reserve_start_at.blank?
      reserve_start_at.min
    else
      nil
    end
  end

  def reserve_start_meridian
    case
    when @reserve_start_meridian
      @reserve_start_meridian
    when !reserve_start_at.blank?
      reserve_start_at.strftime("%p")
    else
      nil
    end
  end
  
  def reserve_end_hour
    case
    when @reserve_end_hour
      @reserve_end_hour
    when !reserve_end_at.blank?
      hour = reserve_end_at.hour.to_i % 12
      hour == 0 ? 12 : hour
    else
      nil
    end
  end

  def reserve_start_date
    case
    when @reserve_start_date
      @reserve_start_date
    when !reserve_start_at.blank?
      reserve_start_at.strftime("%m/%d/%Y")
    else
      nil
    end
  end

  def reserve_end_min
    case
    when @reserve_end_min
      @reserve_end_min
    when !reserve_end_at.blank?
      reserve_end_at.min
    else
      nil
    end
  end

  def reserve_end_meridian
    reserve_end_at.nil? ? nil : reserve_end_at.strftime("%p")
  end
  
  def reserve_end_date
    reserve_end_at.nil? ? nil : reserve_end_at.strftime("%m/%d/%Y")
  end

  def duration_value
    return nil unless reserve_end_at && reserve_start_at

    if !@duration_value
      # default to minutes
      @duration_value = (reserve_end_at - reserve_start_at) / 60
      @duration_unit  = 'minutes'
    end
    @duration_value.to_i
  end

  def duration_unit
    # default to minutes
    @duration_unit ||= 'minutes'
  end

  def duration_mins
    if @duration_mins
      @duration_mins.to_i
    elsif reserve_end_at and reserve_start_at
      @duration_mins = (reserve_end_at - reserve_start_at) / 60
    else
      @duration_mins = 0
    end
  end

  def actual_duration_mins
    if @actual_duration_mins
      @actual_duration_mins.to_i
    elsif actual_end_at && actual_start_at
      @actual_duration_mins = (actual_end_at - actual_start_at) / 60
    else
      @duration_mins = 0
    end
  end

  def actual_start_date
    case
    when @actual_start_date
      @actual_start_date
    when !actual_start_at.blank?
      actual_start_at.strftime("%m/%d/%Y")
    else
      nil
    end
  end

  def actual_start_hour
    case
    when @actual_start_hour
      @actual_start_hour.to_i
    when !actual_start_at.blank?
      hour = actual_start_at.hour.to_i % 12
      hour == 0 ? 12 : hour
    else
      nil
    end
  end

  def actual_start_min
    case
    when @actual_start_min
      @actual_start_min.to_i
    when !actual_start_at.blank?
      actual_start_at.min
    else
      nil
    end
  end

  def actual_start_meridian
    case
    when @actual_start_meridian
      @actual_start_meridian
    when !actual_start_at.blank?
      actual_start_at.strftime("%p")
    else
      nil
    end
  end

  def actual_end_date
    case
    when @actual_end_date
      @actual_end_date
    when !actual_end_at.blank?
      actual_end_at.strftime("%m/%d/%Y")
    else
      nil
    end
  end

  def actual_end_hour
    case
    when @actual_end_hour
      @actual_end_hour.to_i
    when !actual_end_at.blank?
      hour = actual_end_at.hour.to_i % 12
      hour == 0 ? 12 : hour
    else
      nil
    end
  end

  def actual_end_min
    case
    when @actual_end_min
      @actual_end_min.to_i
    when !actual_end_at.blank?
      actual_end_at.min
    else
      nil
    end
  end

  def actual_end_meridian
    case
    when @actual_end_meridian
      @actual_end_meridian
    when !actual_end_at.blank?
      actual_end_at.strftime("%p")
    else
      nil
    end
  end

  # return the cheapest available price policy that
  # * is not expired
  # * is not restricted
  # * is included in the provided price groups
  def cheapest_price_policy(groups = [])
    return nil if groups.empty?
    min = nil
    cheapest_total = 0
    instrument.current_price_policies.each { |pp|
      if !pp.expired? && !pp.restrict_purchase? && groups.include?(pp.price_group)
        costs = pp.estimate_cost_and_subsidy(reserve_start_at, reserve_end_at)
        unless costs.nil?
          total = costs[:cost] - costs[:subsidy]
          if min.nil? || total < cheapest_total
            cheapest_total = total
            min = pp
          end
        end
      end
    }
    min
  end

  # return the longest available reservation window for the groups
  def longest_reservation_window(groups = [])
    pgps     = instrument.price_group_products.find(:all, :conditions => {:price_group_id => groups.collect{|pg| pg.id}})
    pgps.collect{|pgp| pgp.reservation_window}.max
  end

  def can_switch_instrument_on?(check_off = true)
    return false if cancelled?
    return false unless instrument.relay_ip?   # is relay controlled
    return false if can_switch_instrument_off?(false) if check_off # mutually exclusive
    return false unless actual_start_at.nil?   # already turned on
    return false unless actual_end_at.nil?     # already turned off
    return false if reserve_end_at < Time.zone.now # reservation is already over (missed reservation)
    return can_start_early? if reserve_start_at > Time.zone.now
    true
  end

  def can_switch_instrument_off?(check_on = true)
    return false unless instrument.relay_ip?  # is relay controlled
    return false if can_switch_instrument_on?(false) if check_on  # mutually exclusive
    return false unless actual_end_at.nil?    # already ended
    return false if actual_start_at.nil?      # hasn't been started yet
    true
  end

  def can_kill_power?
    return false if actual_start_at.nil?
    return false unless Reservation.find(:first, :conditions => ['actual_start_at > ? AND instrument_id = ? AND id <> ? AND actual_end_at IS NULL', actual_start_at, instrument_id, id]).nil?
    true
  end

  def can_start_early?
    return false if reserve_start_at > Time.zone.now.advance(:minutes => 2) # reserve start is more than 2 minutes in the future
    # no other reservation ongoing; no res between now and reserve_start;
    return false unless Reservation.find(:first,
                                         :conditions => ["((reserve_start_at > ? AND reserve_start_at < ?) OR actual_start_at IS NOT NULL) AND reservations.instrument_id = ? AND actual_end_at IS NULL AND (order_detail_id IS NULL OR order_details.state = 'new' OR order_details.state = 'inprocess')", Time.zone.now, reserve_start_at, instrument_id],
                                         :joins => 'LEFT JOIN order_details ON order_details.id = reservations.order_detail_id').nil?
    # Unecessary check when early start time was reduced from 30 minutes to 2 minutes.  Uncomment to revert. JRG
    # no schedule rule breaks between now and reserve_start
    # return instrument_is_available_to_reserve?(Time.zone.now, reserve_start_at)
    true
  end

  def cancelled?
    !canceled_at.nil?
  end

  # can the CUSTOMER cancel the order
  def can_cancel?
    canceled_at.nil? && reserve_start_at > Time.zone.now && actual_start_at.nil? && actual_end_at.nil?
  end

  def can_edit?
    return true if id.nil? # object is new and hasn't been saved to the DB successfully
    
    # TODO more robust logic?
    can_cancel?
  end

  # TODO does this need to be more robust?
  def can_edit_actuals?
    return false if order_detail.nil?
    order_detail.complete?
  end

  def reservation_changed?
    changes.any? { |k,v| k == 'reserve_start_at' || k == 'reserve_end_at' }
  end

  def to_s
    return super unless reserve_start_at && reserve_end_at

    if reserve_start_at.day == reserve_end_at.day
      str = "#{reserve_start_at.strftime("%a, %m/%d/%Y %l:%M %p")} - #{reserve_end_at.strftime("%l:%M %p")}"
    else
      str = "#{reserve_start_at.strftime("%a, %m/%d/%Y %l:%M %p")} - #{reserve_end_at.strftime("%a, %m/%d/%Y %l:%M %p")}"
    end
    str + (canceled_at ? ' (Cancelled)' : '')
  end

  def actuals_string
    if actual_start_at.nil? && actual_end_at.nil?
      "No actual times recorded"
    elsif actual_start_at.nil?
      "??? - #{actual_end_at.strftime("%m/%d/%Y %l:%M %p")} "
    elsif actual_end_at.nil?
      "#{actual_start_at.strftime("%m/%d/%Y %l:%M %p")} - ???"
    else
      if actual_start_at.day == actual_end_at.day
        "#{actual_start_at.strftime("%m/%d/%Y %l:%M %p")} - #{actual_end_at.strftime("%l:%M %p")}"
      else
        "#{actual_start_at.strftime("%m/%d/%Y %l:%M %p")} - #{actual_end_at.strftime("%m/%d/%Y %l:%M %p")}"
      end
    end
  end

  def valid_before_purchase?
    satisfies_minimum_length? &&
    satisfies_maximum_length? &&
    instrument_is_available_to_reserve? &&
    in_the_future? &&
    in_window? &&
    does_not_conflict_with_other_reservation?
  end

  def has_actuals?
    actual_start_at && actual_end_at
  end

  protected

  def has_order_detail?
    !self.order_detail.nil?
  end

end
