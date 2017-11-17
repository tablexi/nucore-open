class AdminReservationForm

  include ActiveModel::Validations

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

  # validates :max_end_date

  def initialize(reservation)
    @reservation = reservation
  end

  def assign_attributes(attrs)
    @reservation.assign_attributes(attrs.except(:repeat_frequency, :repeat_end_date))
    @repeat_frequency = attrs[:repeat_frequency]
    @repeat_end_date = attrs[:repeat_end_date]
  end

  def save
    if [@reservation, self].map(&:valid?).all?
      @reservation.save
      create_recurring_reservations
    else
      self.errors.merge(@registration.errors)
      false
    end
  end

  def create_recurring_reservations
    case repeat_frequency
    when "Daily"
      reservation = build_next_reservation(1.day, @reservation)

      while reservation.reserve_start_date <= repeat_end_date
        reservation.save
        reservation = build_next_reservation(1.day, reservation)
      end
    when "Weekdays Only"
    when "Weekly"
      build_next_reservation(1.week)
    when "Monthly"
      build_next_reservation(1.month)
    else
      raise ArgumentError
    end

    true
  end

  def build_next_reservation(increment, previous_reservation)
    reservation = previous_reservation.dup
    reservation.reserve_start_date += increment
    reservation.reserve_end_date += increment
  end

end
