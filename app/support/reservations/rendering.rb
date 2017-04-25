# Support for displaying Reservations in various formats
module Reservations::Rendering

  def display_start_at
    actual_start_at || reserve_start_at
  end

  def display_end_at
    actual_end_at || reserve_end_at
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
