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

  def self.not_cancelled
    where(:canceled_at => nil)
  end

  def self.not_started
    where(:actual_start_at => nil)
  end

  def self.not_this_reservation(reservation)
    # old version
    # where('reservations.id <> ?', id || 0)

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

  def assign_actuals_off_reserve
    self.actual_start_at ||= self.reserve_start_at
    self.actual_end_at   ||= self.reserve_end_at
  end

  def save_as_user!(user)
    if (user.operator_of?(product.facility))
      @reserved_by_admin = true
      self.save!
    else
      @reserved_by_admin = false
      self.save_extended_validations!
    end
  end

  def admin?
    order.nil? && !blackout?
  end

  def blackout?
    blackout.present?
  end

  def can_start_early?
    return false if reserve_start_at > Time.zone.now.advance(:minutes => 5) # reserve start is more than 5 minutes in the future
    # no other reservation ongoing; no res between now and reserve_start;
    return false unless Reservation.find(:first,
                                         :conditions => ["((reserve_start_at > ? AND reserve_start_at < ?) OR actual_start_at IS NOT NULL) AND reservations.product_id = ? AND actual_end_at IS NULL AND (order_detail_id IS NULL OR order_details.state = 'new' OR order_details.state = 'inprocess')", Time.zone.now, reserve_start_at, product_id],
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

end
