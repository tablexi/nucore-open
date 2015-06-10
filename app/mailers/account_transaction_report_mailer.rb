class AccountTransactionReportMailer < BaseMailer
  def csv_report_email(to_address, order_detail_ids, date_range_field)
    report = Reports::AccountTransactionsReport.new(
      OrderDetail.where(id: order_detail_ids),
      date_range_field: date_range_field)

    attachments['transaction_report.csv'] = report.to_csv
    mail(to: to_address, subject: "Transaction Export") do |format|
      format.text { render(text: '') }
    end
  end
end
