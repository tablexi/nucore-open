# frozen_string_literal: true

module OrderDetailsCsvExport

  extend ActiveSupport::Concern
  include CsvEmailAction

  def handle_csv_search
    yield_email_and_respond_for_report do |email|
      order_detail_ids = @order_details.respond_to?(:pluck) ? @order_details.pluck(:id) : @order_details.map(&:id)
      AccountTransactionReportMailer.with(
        to_address: email,
        order_detail_ids: order_detail_ids,
        date_range_field: @date_range_field,
        label_key_prefix: @label_key_prefix
      ).csv_report_email.deliver_later
    end
  end

end
