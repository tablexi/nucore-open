module BulkEmail

  module ApplicationHelper

    include Rails.application.routes.url_helpers

    def admin_instrument_send_mail_path(instrument)
      facility_bulk_email_path(
        bulk_email: { user_types: ["customers"] },
        products: [instrument.id],
        start_date: l(Date.today, format: :usa),
        end_date: l(7.days.from_now.to_date, format: :usa),
        return_path: facility_instrument_schedule_path(current_facility, instrument),
        product_id: instrument.id,
      )
    end

    def date_range_selection_link(translation_key, params, start_date: Date.today, end_date: Date.today)
      link_to(
        text(translation_key, scope: "bulk_email.dates.range"),
        params.merge(start_date: format_usa_date(start_date),
                     end_date: format_usa_date(end_date)),
      )
    end

  end

end
