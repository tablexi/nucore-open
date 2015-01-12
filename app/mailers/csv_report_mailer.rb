class CsvReportMailer < ActionMailer::Base
  default from: Settings.email.from

  def csv_report_email(to_address, report)
    attachments[report.filename] = report.to_csv if report.has_attachment?
    mail(to: to_address, subject: report.description) do |format|
      format.text { render(text: report.text_content) }
    end
  end

  def mail(arguments)
    arguments[:to] = Settings.email.fake.to if Settings.email.fake.enabled
    super
  end
end
