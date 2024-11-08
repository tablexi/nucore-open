# frozen_string_literal: true

module CalendarHelper

  def calendar_events_path(facility, product, **params)
    opts = {
      format: "js",
      with_details: product.show_details?,
    }
    opts[:view] = "month" if product.daily_booking?
    opts.merge!(params)

    facility_instrument_reservations_path(
      facility,
      product,
      opts
    )
  end

end
