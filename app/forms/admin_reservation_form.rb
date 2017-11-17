class AdminReservationForm

  include ActiveModel::Validations

  delegate :to_key, :to_model, to: :reservation
  delegate :category, :reserve_start_date, :reserve_start_hour,
           :reserve_start_min, :reserve_start_meridian, :duration_mins,
           :reserve_end_date, :reserve_end_hour, :reserve_end_min,
           :reserve_end_meridian, :admin_note, :expires?,
           :expires_mins_before, to: :reservation

  attr_accessor :repeats, :repeat_frequency, :repeat_end_date
  attr_reader :reservation

  # validates :max_end_date

  def initialize(reservation)
    @reservation = reservation
  end

  def assign_attributes(attrs)
    @reservation.assign_attributes(attrs.except(:repeats?, :repeat_interval, :repeat_num))
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

  def repeats?
    !!repeats
  end

end
