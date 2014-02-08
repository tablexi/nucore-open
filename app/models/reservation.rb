require "date"

class Reservation < ActiveRecord::Base
  include DateHelper
  include Reservations::DateSupport
  include Reservations::Validations
  include Reservations::Rendering
  include Reservations::RelaySupport
  include Reservations::MovingUp

  # Associations
  #####
  belongs_to :product
  belongs_to :order_detail, :inverse_of => :reservation
  belongs_to :canceled_by_user, :foreign_key => :canceled_by, :class_name => 'User'

  ## Virtual attributes
  #####

  # Represents a resevation time that is unavailable, but is not an admin reservation
  # Used by timeline view
  attr_accessor     :blackout
  attr_writer       :note

  # used for overriding certain restrictions
  attr_accessor :reserved_by_admin

  # Delegations
  #####
  delegate :note, :ordered_on_behalf_of?, :complete?, :account, :order,
      :to => :order_detail, :allow_nil => true

  delegate :user, :account, :to => :order, :allow_nil => true
  delegate :facility, :to => :product, :allow_nil => true
  delegate :owner, :to => :account, :allow_nil => true


  ## AR Hooks
  after_save :save_note
  after_update :auto_save_order_detail, :if => :order_detail

  # Scopes
  #####
  def self.active
    not_cancelled.
    where("(orders.state = 'purchased' OR orders.state IS NULL)").
    joins_order
  end

  def self.joins_order
    joins('LEFT JOIN order_details ON order_details.id = reservations.order_detail_id').
    joins('LEFT JOIN orders ON orders.id = order_details.order_id')
  end

  def self.admin
    where(:order_detail_id => nil)
  end

  def self.not_cancelled
    where(:canceled_at => nil)
  end

  def self.not_started
    where(:actual_start_at => nil)
  end

  def self.not_ended
    where(:actual_end_at => nil)
  end

  def self.not_this_reservation(reservation)
    if reservation.id
      where('reservations.id <> ?', reservation.id)
    else
      scoped
    end
  end

  def self.today
    for_date(Time.zone.now)
  end

  def self.for_date(date)
    in_range(date.beginning_of_day, date.end_of_day)
  end

  def self.in_range(start_time, end_time)
    where('reserve_end_at >= ?', start_time).
    where('reserve_start_at < ?', end_time)
  end

  def self.upcoming(t=Time.zone.now)
    # If this is a named scope differences emerge between Oracle & MySQL on #reserve_end_at querying.
    # Eliminate by letting Rails filter by #reserve_end_at
    reservations=find(:all, :conditions => "reservations.canceled_at IS NULL AND (orders.state = 'purchased' OR orders.state IS NULL)", :order => 'reserve_end_at asc', :joins => ['LEFT JOIN order_details ON order_details.id = reservations.order_detail_id', 'LEFT JOIN orders ON orders.id = order_details.order_id'])
    reservations.delete_if{|r| r.reserve_end_at < t}
    reservations
  end

  def self.overlapping(start_at, end_at)
    # remove millisecond precision from time
    tstart_at = Time.zone.parse(start_at.to_s)
    tend_at   = Time.zone.parse(end_at.to_s)

    where("((reserve_start_at <= :start AND reserve_end_at >= :end) OR
          (reserve_start_at >= :start AND reserve_end_at <= :end) OR
          (reserve_start_at <= :start AND reserve_end_at > :start) OR
          (reserve_start_at < :end AND reserve_end_at >= :end) OR
          (reserve_start_at = :start AND reserve_end_at = :end))",
          :start => tstart_at, :end => tend_at)
  end

  # Instance Methods
  #####

  def start_reservation!
    self.actual_start_at = Time.zone.now
    start_in_grace_period if in_grace_period?
    save!
  end

  def end_reservation!
    self.actual_end_at = Time.zone.now
    save!
    # reservation is done, now give the best price
    order_detail.assign_price_policy
    order_detail.save!
  end


  def round_reservation_times
    self.reserve_start_at = time_ceil(self.reserve_start_at) if self.reserve_start_at
    self.reserve_end_at   = time_ceil(self.reserve_end_at) if self.reserve_end_at
  end

  def assign_actuals_off_reserve
    self.actual_start_at ||= self.reserve_start_at
    self.actual_end_at   ||= self.reserve_end_at
  end

  def save_as_user(user)
    if (user.operator_of?(product.facility))
      @reserved_by_admin = true
      self.save
    else
      @reserved_by_admin = false
      self.save_extended_validations
    end
  end

  def save_as_user!(user)
    raise ActiveRecord::RecordInvalid.new(self) unless save_as_user(user)
  end

  def admin?
    order.nil? && !blackout?
  end

  def blackout?
    blackout.present?
  end

  def can_start_early?
    return false unless in_grace_period?
    # no other reservation ongoing; no res between now and reserve_start;
    where = <<-SQL
      reserve_start_at > ?
      AND reserve_start_at < ?
      AND actual_start_at IS NULL
      AND reservations.product_id = ?
      AND (order_detail_id IS NULL OR order_details.state = 'new' OR order_details.state = 'inprocess')
    SQL

    Reservation.joins(:order_detail).where(where, Time.zone.now, reserve_start_at, product_id).first.nil?
  end

  def cancelled?
    !canceled_at.nil?
  end

  # can the CUSTOMER cancel the order
  def can_cancel?
    canceled_at.nil? && reserve_start_at > Time.zone.now && actual_start_at.nil? && actual_end_at.nil?
  end

  def can_customer_edit?
    !cancelled? && !complete? && reserve_start_at > Time.zone.now
  end

  # can the ADMIN edit the reservation?
  def can_edit?
    return true if id.nil? # object is new and hasn't been saved to the DB successfully

    # an admin can edit the reservation times as long as the reservation has not been cancelled,
    # even if it is in the past.
    !cancelled?
  end

  # TODO does this need to be more robust?
  def can_edit_actuals?
    return false if order_detail.nil?
    complete?
  end

  def reservation_changed?
    changes.any? { |k,v| k == 'reserve_start_at' || k == 'reserve_end_at' }
  end

  def valid_before_purchase?
    satisfies_minimum_length? &&
    satisfies_maximum_length? &&
    instrument_is_available_to_reserve? &&
    does_not_conflict_with_other_reservation?
  end

  def has_actuals?
    !!(actual_start_at && actual_end_at)
  end

  def requires_but_missing_actuals?
    !!(!cancelled? && product.control_mechanism != Relay::CONTROL_MECHANISMS[:manual] && !has_actuals?)
  end

  protected

  def has_order_detail?
    !self.order_detail.nil?
  end

  private

  def auto_save_order_detail
    if (['actual_start_at', 'actual_end_at', 'reserve_start_at', 'reserve_end_at'] & changes.keys).any?
      order_detail.save
    end
  end

  def save_note
    if order_detail && @note
      order_detail.note = @note
      order_detail.save
    end
  end

  def in_grace_period?(at = Time.zone.now)
    at = at.to_i
    grace_period_end = reserve_start_at.to_i
    grace_period_begin = (reserve_start_at - grace_period_duration).to_i

    # Compare int values, not timestamps. If you do the
    # latter fractions of a second can cause false positives.
    at >= grace_period_begin && at <= grace_period_end
  end

  def grace_period_duration
    SettingsHelper.setting('reservations.grace_period') || 5.minutes
  end

  def start_in_grace_period
    # Move the reservation time forward so other reservations can't overlap
    # with this one, but only move it forward if there's not already a reservation
    # currently in progress.
    original_start_at = reserve_start_at
    self.reserve_start_at = actual_start_at
    unless does_not_conflict_with_other_reservation?
      self.reserve_start_at = original_start_at
    end
  end
end
