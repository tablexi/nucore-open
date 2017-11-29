class AdminReservationForm

  include ActiveModel::Validations
  include DateHelper

  REPEAT_OPTIONS = %w(
    daily
    weekdays_only
    weekly
    monthly
  ).freeze

  delegate :to_key, :to_model, to: :reservation
  delegate :category, :reserve_start_date, :reserve_start_hour,
           :reserve_start_min, :reserve_start_meridian, :duration_mins,
           :reserve_end_date, :reserve_end_hour, :reserve_end_min,
           :reserve_end_meridian, :admin_note, :expires?,
           :expires_mins_before, to: :reservation
  delegate :assign_times_from_params, to: :reservation

  attr_accessor :repeats, :repeat_frequency, :repeat_end_date
  attr_reader :reservation

  validates :repeat_frequency, inclusion: { in: REPEAT_OPTIONS.map(&:titleize), allow_nil: true }
  validates :repeat_end_date, presence: true

  validate :max_end_date

  def initialize(reservation)
    @reservation = reservation
  end

  def assign_attributes(attrs)
    @reservation.assign_attributes(attrs.except(:repeat_frequency, :repeat_end_date, :repeats))
    @repeats = attrs[:repeats]
    @repeat_frequency = attrs[:repeat_frequency]
    @repeat_end_date = parse_usa_date(attrs[:repeat_end_date])
  end

  def valid?
    [@reservation.valid?, super].each {}
    # errors does not support `merge`
    @reservation.errors.each do |k, errors|
      errors.add(k, errors)
    end
    errors.none?
  end

  def save
    if valid?
      # @reservation.save
      reservations = create_recurring_reservations
      reservations.map(&:save).all?
    else
      false
    end
  end

  def create_recurring_reservations
    recurrence = NuRecurrence.new(reservation.reserve_start_at, reservation.reserve_end_at, until_time: repeat_end_date.end_of_day)

    repeats = case repeat_frequency
    when "Daily"
      recurrence.daily
    when "Weekdays Only"
      recurrence.weekdays
    when "Weekly"
      recurrence.weekly
    when "Monthly"
      recurrence.monthly
    else
      # no repeat
      recurrence.daily.take(1)
    end

    repeats.map do |t|
      @reservation.dup.tap do |res|
        res.assign_attributes(reserve_start_at: t.start_time, reserve_end_at: t.end_time)
      end
    end
  end

  def max_end_date
    if repeat_end_date > Time.current + 12.weeks
      errors.add :repeat_end_date, :too_far_in_future
    end
  end

end

#####

# NuRecurrence.new(30.days.ago, 30.days.ago + 1.hour).weekdays.take(10).map { |t| [t.start_time, t.end_time] }
# NuRecurrence.new(30.days.ago, 30.days.ago + 1.hour, until_time: 10.days.ago).weekdays.map { |t| [t.start_time, t.end_time] }
class NuRecurrence

  include Enumerable
  delegate :each, to: :to_enum

  def initialize(start_at, end_at, until_time: nil)
    @until_time = until_time
    @schedule = IceCube::Schedule.new(
      start_at, end_time: end_at)
  end

  def daily
    @schedule.add_recurrence_rule IceCube::Rule.daily.until(@until_time)
    self
  end

  def weekdays
    @schedule.add_recurrence_rule IceCube::Rule.weekly.day(:monday, :tuesday, :wednesday, :thursday, :friday).until(@until_time)
    self
  end

  def weekly
    @schedule.add_recurrence_rule IceCube::Rule.weekly.until(@until_time)
    self
  end

  def monthly
    @schedule.add_recurrence_rule IceCube::Rule.monthly.until(@until_time)
    self
  end

  def to_enum
    @schedule.all_occurrences_enumerator
  end

end
