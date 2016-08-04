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
  belongs_to :order_detail, inverse_of: :reservation
  has_one :order, through: :order_detail
  belongs_to :canceled_by_user, foreign_key: :canceled_by, class_name: "User"

  ## Virtual attributes
  #####

  # Represents a resevation time that is unavailable, but is not an admin reservation
  # Used by timeline view
  attr_accessor :blackout

  # used for overriding certain restrictions
  attr_accessor :reserved_by_admin

  # Delegations
  #####
  delegate :note, :note=, :ordered_on_behalf_of?, :complete?, :account, :order,
           :problem?, :complete!, to: :order_detail, allow_nil: true

  delegate :account, :in_cart?, :user, to: :order, allow_nil: true
  delegate :facility, to: :product, allow_nil: true
  delegate :lock_window, to: :product, prefix: true
  delegate :owner, to: :account, allow_nil: true

  ## AR Hooks
  after_update :auto_save_order_detail, if: :order_detail

  # Scopes
  #####

  scope :non_user, -> { where(type: %w(AdminReservation OfflineReservation)) }

  def self.active
    not_canceled
      .user
      .where(orders: { state: ["purchased", nil] })
      .joins_order
  end

  scope :ends_in_the_future, lambda {
    where("reserve_end_at IS NULL OR reserve_end_at > ?", Time.current)
  }

  def self.joins_order
    joins("LEFT JOIN order_details ON order_details.id = reservations.order_detail_id")
      .joins("LEFT JOIN orders ON orders.id = order_details.order_id")
  end

  scope :not_canceled, -> { where(canceled_at: nil) }
  scope :not_started, -> { where(actual_start_at: nil) }
  scope :not_ended, -> { where(actual_end_at: nil) }

  def self.not_this_reservation(reservation)
    if reservation.id
      where("reservations.id <> ?", reservation.id)
    else
      all
    end
  end

  scope :ongoing, -> { not_ended.where("actual_start_at <= ?", Time.current) }

  def self.today
    for_date(Time.zone.now)
  end

  def self.for_date(date)
    in_range(date.beginning_of_day, date.end_of_day)
  end

  def self.in_range(start_time, end_time)
    where("reserve_end_at >= ?", start_time)
      .where("reserve_start_at < ?", end_time)
  end

  def self.upcoming(t = Time.zone.now)
    # If this is a named scope differences emerge between Oracle & MySQL on #reserve_end_at querying.
    # Eliminate by letting Rails filter by #reserve_end_at
    joins("LEFT JOIN order_details ON order_details.id = reservations.order_detail_id")
      .joins("LEFT JOIN orders ON orders.id = order_details.order_id")
      .where(canceled_at: nil, "orders.state" => [nil, "purchased"])
      .order(reserve_end_at: :asc)
      .to_a
      .delete_if { |reservation| reservation.reserve_end_at < t }
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
          start: tstart_at, end: tend_at)
  end

  def self.relay_in_progress
    where("actual_start_at IS NOT NULL AND actual_end_at IS NULL")
  end

  def self.upcoming_offline(start_at_limit)
    user
      .where(product_id: OfflineReservation.current.pluck(:product_id))
      .not_canceled
      .not_ended
      .merge(OrderDetail.purchased)
      .joins(:order_detail)
      .where(order_details: { state: %w(new inprocess), problem: false })
      .where("reserve_start_at <= ?", start_at_limit)
  end

  scope :user, -> { where(type: nil) }

  # Instance Methods
  #####

  def end_at_required?
    true
  end

  def start_reservation!
    product.schedule.products.map(&:started_reservations).flatten.each(&:complete!)
    self.actual_start_at = Time.zone.now
    save!
  end

  def end_reservation!
    self.actual_end_at = Time.zone.now
    save!
    # reservation is done, now give the best price
    order_detail.assign_price_policy
    order_detail.complete!
  end

  def round_reservation_times
    interval = product.reserve_interval.minutes # Round to the nearest reservation interval
    self.reserve_start_at = time_ceil(reserve_start_at, interval) if reserve_start_at
    self.reserve_end_at   = time_ceil(reserve_end_at, interval) if reserve_end_at
    self
  end

  def assign_actuals_off_reserve
    self.actual_start_at ||= reserve_start_at
    self.actual_end_at   ||= reserve_end_at
  end

  def save_as_user(user)
    if user.operator_of?(product.facility)
      @reserved_by_admin = true
      save
    else
      @reserved_by_admin = false
      save_extended_validations
    end
  end

  def save_as_user!(user)
    raise ActiveRecord::RecordInvalid.new(self) unless save_as_user(user)
  end

  def admin?
    order.nil? && !blackout?
  end

  def admin_removable?
    true
  end

  def blackout?
    blackout.present?
  end

  def can_start_early?
    return false unless in_grace_period?
    # no other reservation ongoing; no res between now and reserve_start;

    Reservation
      .not_started
      .where("reserve_start_at > :now", now: Time.current)
      .where("reserve_start_at < :reserve_start_at", reserve_start_at: reserve_start_at)
      .where(product_id: product_id)
      .joins(:order_detail)
      .where("order_detail_id IS NULL OR order_details.state IN ('new', 'inprocess')")
      .none?
  end

  def canceled?
    canceled_at.present?
  end

  # can the CUSTOMER cancel the order
  def can_cancel?
    canceled_at.nil? && reserve_start_at > Time.zone.now && actual_start_at.nil? && actual_end_at.nil?
  end

  def can_customer_edit?
    !canceled? && !complete? && (reserve_start_at_editable? || reserve_end_at_editable?)
  end

  def reserve_start_at_editable?
    before_lock_window? && !started?
  end

  def reserve_end_at_editable?
    outside_lock_window? && Time.zone.now <= reserve_end_at && next_duration_available? && actual_end_at.blank?
  end

  def next_duration_available?
    next_available = product.next_available_reservation(reserve_end_at)

    return false unless next_available

    current_end_at = reserve_end_at.change(sec: 0)
    next_start_at = next_available.reserve_start_at.change(sec: 0)

    current_end_at == next_start_at
  end

  def before_lock_window?
    Time.zone.now < reserve_start_at - product_lock_window.hours
  end

  def outside_lock_window?
    before_lock_window? || Time.zone.now >= reserve_start_at
  end

  def admin_editable?
    new_record? || !canceled?
  end

  # TODO: does this need to be more robust?
  def can_edit_actuals?
    return false if order_detail.nil?
    complete?
  end

  def reservation_changed?
    reserve_start_at_changed? || reserve_end_at_changed?
  end

  def valid_before_purchase?
    satisfies_minimum_length? &&
      satisfies_maximum_length? &&
      instrument_is_available_to_reserve? &&
      does_not_conflict_with_other_reservation?
  end

  def has_actuals?
    actual_start_at.present? && actual_end_at.present?
  end

  def started?
    actual_start_at.present?
  end

  def ongoing?
    !complete? && started? && actual_end_at.blank?
  end

  def requires_but_missing_actuals?
    !!(!canceled? && product.control_mechanism != Relay::CONTROL_MECHANISMS[:manual] && !has_actuals?) # TODO: refactor?
  end

  def locked?
    !(admin_editable? || can_edit_actuals?)
  end

  # Used in instrument utilization reports
  def quantity
    1
  end

  protected

  def has_order_detail?
    !order_detail.nil?
  end

  private

  def auto_save_order_detail
    if (%w(actual_start_at actual_end_at reserve_start_at reserve_end_at) & changes.keys).any?
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
    SettingsHelper.setting("reservations.grace_period") || 5.minutes
  end

end
