module Products::SchedulingSupport

  extend ActiveSupport::Concern

  included do
    belongs_to :schedule, inverse_of: :products
    has_many :schedule_rules
    has_many :reservations, foreign_key: "product_id"

    delegate :reservations, to: :schedule, prefix: true

    before_save :create_default_schedule, unless: :schedule
    before_save :update_schedule_name, if: :name_changed?
  end

  def active_reservations
    reservations.active
  end

  def purchased_reservations
    reservations.joins(order_detail: :order).merge(Order.purchased)
  end

  def started_reservations
    purchased_reservations
      .not_canceled
      .merge(OrderDetail.unreconciled)
      .merge(Reservation.relay_in_progress)
  end

  def visible_reservations(date = nil)
    purchased = purchased_reservations.order(:reserve_start_at)
    admin = admin_reservations
    if date
      purchased = purchased.for_date(date)
      admin = admin.for_date(date)
    end
    purchased + admin
  end

  def active_schedule_reservations
    schedule.reservations.active
  end

  def can_purchase?(group_ids = nil)
    if schedule_rules.empty?
      false
    else
      super
    end
  end

  def schedule_sharing?
    schedule.shared?
  end

  def first_available_hour
    return 0 unless schedule_rules.any?
    schedule_rules.min { |a, b| a.start_hour <=> b.start_hour }.start_hour
  end

  def last_available_hour
    return 23 unless schedule_rules.any?
    max_rule = schedule_rules.max { |a, b| a.hour_floor <=> b.hour_floor }
    max_rule.end_min == 0 ? max_rule.end_hour - 1 : max_rule.end_hour
  end

  def available?(time = Time.zone.now)
    # zero and nil should default to 1 minute
    reservation_length = [min_reserve_mins.to_i, reserve_interval.to_i].max
    reservation = Reservation.new(
      product: self,
      reserve_start_at: time,
      reserve_end_at: time + reservation_length.minutes,
      blackout: true # so it's not considered an admin and allowed to overlap
    )
    reservation.valid?
  end

  # find the next available reservation based on schedule rules and existing reservations
  def next_available_reservation(after = Time.zone.now, duration = 1.minute, options = {})
    rules = rules_for_day after.wday, options[:user]
    # if the user has no schedule rules, there will be no time that they can
    # move the reservation to
    return nil unless rules.any?
    reservation_in_week after, duration, rules, options
  end

  def available_schedule_rules(user)
    if requires_approval? && user
      schedule_rules.available_to_user user
    else
      schedule_rules
    end
  end

  def offline?
    offline_reservations.current.any?
  end

  def online!
    offline_reservations.current.update_all(reserve_end_at: Time.current)
  end

  def online?
    !offline?
  end

  private

  def reservation_in_week(after, duration, rules, options)
    day_of_week = after.wday

    0.upto(6) do |i|
      day_of_week = (day_of_week + i) % 6

      rules.each do |rule|
        finder = ReservationFinder.new(after, rule, options)
        reservation = finder.next_reservation self, duration
        return reservation if reservation
      end

      # advance to start of next day
      after = after.end_of_day + 1.second
      return nil if options[:until] && after >= options[:until]
    end

    # no availability found in this week; check next week
    reservation_in_week after, duration, rules, options
  end

  #
  # find rules for day of week, sort by start hour
  def rules_for_day(day_of_week, user)
    rules = available_schedule_rules(user).select { |r| r.send("on_#{Date::ABBR_DAYNAMES[day_of_week].downcase}".to_sym) }
    rules.sort_by(&:start_hour)
  end

  def create_default_schedule
    self.schedule = Schedule.create(name: "#{name} Schedule", facility: facility)
  end

  def update_schedule_name
    if schedule.name == "#{name_was} Schedule"
      schedule.update_attributes(name: "#{name} Schedule")
    end
  end

  class ReservationFinder

    attr_accessor :time, :rule, :day_start, :day_end, :options

    def initialize(time, rule, options = {})
      self.time = time
      self.rule = rule
      self.day_start = Time.zone.local(time.year, time.month, time.day, rule.start_hour, rule.start_min, 0)
      self.day_end   = Time.zone.local(time.year, time.month, time.day, rule.end_hour, rule.end_min, 0)
      self.options   = options
      adjust_time
    end

    def adjust_time
      # we can't start before the rules say we can
      self.time = day_start if time < day_start

      # check for conflicts with rule interval/duration time and adjust to next interval if necessary
      duration_mins = rule.instrument.reserve_interval.to_i
      self.time += (duration_mins - time.min % duration_mins).minutes unless time.min % duration_mins == 0
    end

    def next_reservation(reserver, duration)
      start_time = time

      while start_time < day_end
        reservation = reserver.reservations.new(reserve_start_at: start_time, reserve_end_at: start_time + duration)

        conflict = reservation.conflicting_reservation(exclude: options[:exclude])
        return reservation if conflict.nil?

        start_time = conflict.reserve_end_at
      end
    end

  end

end
