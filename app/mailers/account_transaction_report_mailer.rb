# frozen_string_literal: true

class AccountTransactionReportMailer < CsvReportMailer

  def csv_report_email
    order_detail_ids = params[:order_detail_ids]
    date_range_field = params[:date_range_field]
    label_key_prefix = params[:label_key_prefix]

    order_details = OrderDetail.where_ids_in(order_detail_ids)
                               .preload(:product, :order_status, :reservation, :account, order: [:facility, :user])

    @report = Reports::AccountTransactionsReport.new(
      order_details,
      date_range_field: date_range_field,
      label_key_prefix: label_key_prefix,
    )

    super
  end

end
