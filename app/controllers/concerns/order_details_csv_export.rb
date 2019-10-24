# frozen_string_literal: true

module OrderDetailsCsvExport

  extend ActiveSupport::Concern
  include CsvEmailAction

  def handle_csv_search
    send_csv_email_and_respond do |email|
      order_detail_ids = @order_details.respond_to?(:pluck) ? @order_details.pluck(:id) : @order_details.map(&:id)
      AccountTransactionReportMailer.csv_report_email(email, order_detail_ids, @date_range_field).deliver_later
    end
  end

end
