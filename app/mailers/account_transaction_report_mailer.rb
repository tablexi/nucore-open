# frozen_string_literal: true

class AccountTransactionReportMailer < CsvReportMailer

  def csv_report_email(to_address, order_detail_ids, date_range_field, use_estimated_cost_label=false)
    order_details = OrderDetail.where_ids_in(order_detail_ids)
                               .preload(:product, :order_status, :reservation, :account, order: [:facility, :user])

    report = Reports::AccountTransactionsReport.new(
      order_details,
      date_range_field: date_range_field,
      use_estimated_cost_label: use_estimated_cost_label,
    )

    super(to_address, report)
  end

end
