module Reports

  class ExportRawReportsController < ReportsController

    include StatusFilterParams

    def export_all
      generate_report_data_csv
    end

    private

    def email_to_address
      params[:email_to_address].presence || current_user.email
    end

    def raw_report
      Reports::ExportRaw.new(
        facility: current_facility,
        date_range_field: params[:date_range_field],
        date_start: @date_start,
        date_end: @date_end,
        order_status_ids: @status_ids,
      )
    end

    def generate_report_data_csv
      ExportRawReportMailer.delay.raw_report_email(email_to_address, raw_report)
      if request.xhr?
        render nothing: true
      else
        flash[:notice] = I18n.t("controllers.reports.mail_queued", email: email_to_address)
        redirect_to send("#{action_name}_facility_general_reports_path", current_facility)
      end
    end

  end

end
