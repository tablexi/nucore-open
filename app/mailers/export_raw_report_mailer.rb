class ExportRawReportMailer < BaseMailer # TODO: use CsvReportMailer instead

  def raw_report_email(to_address, report)
    attachments[report.filename] = report.to_csv
    mail(to: to_address, subject: report.description) do |format|
      format.text { render(text: "") }
    end
  end

end
