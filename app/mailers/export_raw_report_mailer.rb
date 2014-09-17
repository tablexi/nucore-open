class ExportRawReportMailer < ActionMailer::Base
  default from: Settings.email.from

  def raw_report_email(to_address, report)
    attachments[report.filename] = report.to_csv
    mail(to: to_address, subject: report.description)
  end

  def mail(arguments)
    arguments[:to] = Settings.email.fake.to if Settings.email.fake.enabled
    super
  end
end
