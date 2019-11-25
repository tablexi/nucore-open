# frozen_string_literal: true

class ProblemReservationForm < SimpleDelegator

  include ActiveModel::Validations

  validates :actual_duration_mins, numericality: { greater_than: 0, allow_blank: false }
  alias reservation __getobj__

  def valid?
    [super, reservation.valid?].each {}
    # Rails 5.2 will give us Errors#merge!
    errors.each do |k, error_messages|
      reservation.errors.add(k, error_messages)
    end
    reservation.errors.none?
  end

  def save
    return unless valid?
    super
  end

  def assign_attributes(attrs)
    super(attrs.merge(split_times: true, editing_time_data: true))
  end
end
