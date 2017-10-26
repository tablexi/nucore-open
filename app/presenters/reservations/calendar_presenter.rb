module Reservations

  class CalendarPresenter < DelegateClass(Reservation)

    def as_calendar_object(options = {})
      calendar_object_default.merge(reservation_options(options))
    end

    private

    def reservation_options(options)
      if order.present?
        if options[:with_details].present?
          {
            "email" => order.user.email,
            "title" => order.user.full_name,
          }
        else
          {}
        end
      elsif offline?
        { "title" => "Instrument Offline" }
      else
        { "title" => self.model_name.human }
      end
    end

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

end
