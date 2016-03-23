# Support for displaying Reservations in various formats
module Reservations::Rendering

  def display_start_at
    actual_start_at || reserve_start_at
  end

  def display_end_at
    actual_end_at || reserve_end_at
  end

  def to_s
    return super unless reserve_start_at && reserve_end_at
    range = range_to_s(display_start_at, display_end_at)
    range += " (Canceled)" if canceled_at.present?
    range
  end

  def reserve_to_s
    range_to_s(reserve_start_at, reserve_end_at)
  end

  def range_to_s(start_at, end_at)
    if start_at.day == end_at.day
      "#{I18n.l(start_at)} - #{I18n.l(end_at, format: :timeonly)}"
    else
      "#{I18n.l(start_at)} - #{I18n.l(end_at)}"
    end
  end

  def actuals_string
    if actual_start_at.blank? && actual_end_at.blank?
      "No actual times recorded"
    elsif !started?
      "??? - #{I18n.l(actual_end_at)} "
    elsif actual_end_at.blank?
      "#{I18n.l(actual_start_at)} - ???"
    else
      range_to_s(actual_start_at, actual_end_at)
    end
  end

  def as_calendar_object(options = {})
    calendar_object_default.merge(
      if order.present?
        if options[:with_details].present?
          {
            "admin" => false,
            "email" => order.user.email,
            "name"  => order.user.full_name.to_s,
            "title" => "#{order.user.first_name}\n#{order.user.last_name}",
          }
        else
          {}
        end
      else
        { "admin" => true, "title" => "Admin\nReservation" }
      end,
    )
  end

  private

  def calendar_object_default
    {
      "start" => I18n.l(display_start_at, format: :calendar),
      "end" => I18n.l(display_end_at, format: :calendar),
      "allDay" => false,
      "title" => "Reservation",
      "product" => product.name,
    }
  end

end
