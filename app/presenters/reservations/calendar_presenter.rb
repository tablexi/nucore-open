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
            title: order.user.full_name,
            email: order.user.email,
          }
        else
          {}
        end
      elsif offline?
        {
          title: "Instrument Offline",
          email: created_by.try(:full_name),
        }
      elsif expires_mins_before.present?
        {
          title: model_name.human,
          email: created_by.try(:full_name),
          expiration: "Expires #{display_as_time(expires_mins_before)} prior",
        }
      else
        {
          title: model_name.human,
          email: created_by.try(:full_name),
        }
      end
    end

    def calendar_object_default
      {
        start: I18n.l(display_start_at, format: :calendar),
        end: I18n.l(display_end_at, format: :calendar),
        allDay: false,
        title: model_name.human,
        product: product.name,
      }
    end

  end

end
