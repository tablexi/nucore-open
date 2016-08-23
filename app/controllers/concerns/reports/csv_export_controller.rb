module Reports

  module CsvExportController

    def export_all
      generate_report_data_csv
    end

    private

    def email_to_address
      params[:email_to_address].presence || current_user.email
    end

    def generate_report_data_csv
      ExportRawReportMailer.delay.raw_report_email(email_to_address, raw_report)
      if request.xhr?
        render nothing: true
      else
        flash[:notice] = I18n.t("controllers.reports.mail_queued", email: email_to_address)
        redirect_to success_redirect_path
      end
    end

  end

end
