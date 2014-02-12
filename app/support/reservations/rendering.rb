# Support for displaying Reservations in various formats
module Reservations::Rendering

  # Will display the actual start time if it's available, otherwise fall back to reserve time
  def display_start_at
    actual_start_at || reserve_start_at
  end

  def display_end_at
    actual_end_at || reserve_end_at
  end

  def to_s
    return super unless reserve_start_at && reserve_end_at

    str = range_to_s(display_start_at, display_end_at)

    str + (canceled_at ? ' (Cancelled)' : '')
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
    if actual_start_at.nil? && actual_end_at.nil?
      "No actual times recorded"
    elsif actual_start_at.nil?
      "??? - #{I18n.l(actual_end_at)} "
    elsif actual_end_at.nil?
      "#{I18n.l(actual_start_at)} - ???"
    else
      range_to_s(actual_start_at, actual_end_at)
    end
  end

  def as_calendar_object(options={})
    # initialize result with defaults
    calendar_object = {
      "start"  => I18n.l(actual_start_at || reserve_start_at, format: :calendar),
      "end"    => I18n.l(actual_end_at || reserve_end_at, format: :calendar),
      "allDay" => false,
      "title"  => "Reservation",
      "product" => product.name
    }

    overrides = {}
    if order
      if options[:with_details]
        overrides = {
          "admin"       => false,
          "email"        => order.user.email,
          "name"        => "#{order.user.full_name}",
          "title"       => "#{order.user.first_name}\n#{order.user.last_name}"
        }
      end
    else
      overrides = {
          "admin"       => true,
          "title"       => "Admin\nReservation"
        }
    end

    calendar_object.merge!(overrides)

    calendar_object
  end
end
