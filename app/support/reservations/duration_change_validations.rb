class Reservations::DurationChangeValidations
  include ActiveModel::Validations

  attr_reader :reservation

  validate :start_time_not_changed, unless: Proc.new { |r| r.reservation.reserve_start_at_editable? }
  validate :duration_not_shortened, if: Proc.new { |r| Time.zone.now >= r.reservation.reserve_start_at }

  def initialize(reservation)
    @reservation = reservation
  end

  def copy_errors!
    errors.each do |e|
      reservation.errors.add(e)
    end
  end

  def invalid?(context = nil)
    super(context)
    copy_errors!
  end

  def valid?(context = nil)
    super(context)
    copy_errors!
  end

  def start_time_not_changed
    if reservation.reserve_start_at_changed?
      errors.add(:reserve_start_at, I18n.t('activerecord.errors.models.reservation.change_reserve_start_at'))
    end
  end

  def duration_not_shortened
    if reservation.reserve_end_at_changed? && reservation.reserve_end_at < reservation.reserve_end_at_was
      errors.add(:reserve_end_at, I18n.t('activerecord.errors.models.reservation.shorten_reserve_end_at'))
    end
  end
end
