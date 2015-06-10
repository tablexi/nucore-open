class AccountTransactionReportMailer < CsvReportMailer
  def csv_report_email(to_address, order_detail_ids, date_range_field)
    report = Reports::AccountTransactionsReport.new(
      OrderDetail.where(id: order_detail_ids),
      date_range_field: date_range_field)

    super(to_address, report)
  end
end
