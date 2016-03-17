require 'csv'
class Reports::ExportRaw
  include DateHelper

  attr_reader :order_status_ids, :facility, :date_range_field

  def initialize(arguments)
    [:action_name, :date_end, :date_start, :facility, :order_status_ids].each do |property|
      if arguments[property].present?
        instance_variable_set("@#{property}".to_sym, arguments[property])
      else
        raise ArgumentError, "Required argument '#{property}' is missing"
      end
    end
    @date_range_field = arguments[:date_range_field] || 'journal_or_statement_date'
  end

  def date_start
    @date_start.in_time_zone
  end

  def date_end
    @date_end.in_time_zone
  end

  def report_data
    @report_data ||= report_data_query
  end

  def to_csv
    (csv_header + csv_body).to_s
  end

  def filename
    "#{@action_name}_#{formatted_compact_date_range}.csv"
  end

  def description
    "#{@action_name.capitalize} Raw Export, #{formatted_date_range}"
  end

  def formatted_date_range
    "#{format_usa_date(date_start)} - #{format_usa_date(date_end)}"
  end

  def formatted_compact_date_range
    "#{date_start.strftime("%Y%m%d")}-#{date_end.strftime("%Y%m%d")}"
  end

  private

  def report_hash
    transformers.reduce(default_report_hash) do |result, class_name|
      class_name.constantize.new.transform(result)
    end
  end

  def transformers
    Array(Settings.reports.try(:[], "export_raw").try(:[], "transformers"))
  end

  def default_report_hash
    {
      "Facility" => :facility,
      "Order" => :to_s,
      "Ordered At" => -> (od) { od.order.ordered_at },
      "Fulfilled At" => -> (od) { od.fulfilled_at },
      "Order Status" => -> (od) { od.order_status.name },
      "Order State" => :state,
      "Ordered By" => -> (od) { od.order.created_by_user.username },
      "First Name" => -> (od) { od.order.created_by_user.first_name },
      "Last Name" => -> (od) { od.order.created_by_user.last_name },
      "Email" => -> (od) { od.order.created_by_user.email },
      "Purchaser" => -> (od) { od.order.user.username },
      "Purchaser First Name" => -> (od) { od.order.user.first_name },
      "Purchaser Last Name" => -> (od) { od.order.user.last_name },
      "Purchaser Email" => -> (od) { od.order.user.email },
      "Product ID" => -> (od) { od.product.url_name },
      "Product Type" => -> (od) { od.product.type.underscore.humanize },
      "Product" => -> (od) { od.product.name },
      "Quantity" => :quantity,
      "Bundled Products" => -> (od) { od.product.is_a?(Bundle) ? od.product.products.collect(&:name).join(' & ') : nil },
      "Account Type" => -> (od) { od.account.type.underscore.humanize },
      "Affiliate" => -> (od) { od.account.affiliate_to_s },
      "Account" => -> (od) { od.account.account_number },
      "Account Description" => -> (od) { od.account.description_to_s },
      "Account Expiration" => -> (od) { od.account.expires_at },
      "Account Owner" => -> (od) { od.account.owner_user.username },
      "Owner First Name" => -> (od) { od.account.owner_user.first_name },
      "Owner Last Name" => -> (od) { od.account.owner_user.last_name },
      "Owner Email" => -> (od) { od.account.owner_user.email },
      "Price Group" => -> (od) { od.price_policy.try(:price_group).try(:name) },
      "Estimated Cost" => -> (od) { as_currency(od.estimated_cost) },
      "Estimated Subsidy" => -> (od) { as_currency(od.estimated_subsidy) },
      "Estimated Total" => -> (od) { as_currency(od.estimated_total) },
      "Actual Cost" => -> (od) { as_currency(od.actual_cost) },
      "Actual Subsidy" => -> (od) { as_currency(od.actual_subsidy) },
      "Actual Total" => -> (od) { as_currency(od.actual_total) },
      "Reservation Start Time" => -> (od) { od.reservation.reserve_start_at if od.reservation },
      "Reservation End Time" => -> (od) { od.reservation.reserve_end_at if od.reservation },
      "Reservation Minutes" => -> (od) { od.reservation.try(:duration_mins) },
      "Actual Start Time" => -> (od) { od.reservation.actual_start_at if od.reservation },
      "Actual End Time" => -> (od) { od.reservation.actual_end_at if od.reservation },
      "Actual Minutes" => -> (od) { od.reservation.try(:actual_duration_mins) },
      "Canceled At" => -> (od) { od.reservation.canceled_at if od.reservation },
      "Canceled By" => -> (od) { canceled_by_name(od.reservation) if od.reservation },
      "Note" => :note,
      "Disputed At" => -> (od) { od.dispute_at },
      "Dispute Reason" => :dispute_at,
      "Dispute Resolved At" => -> (od) { od.dispute_resolved_at },
      "Dispute Resolved Reason" => :dispute_resolved_reason,
      "Reviewed At" => -> (od) { od.reviewed_at },
      "Statemented On" => -> (od) { od.statement.created_at if od.statement },
      "Journal Date" => -> (od) { od.journal.journal_date if od.journal },
      "Reconciled Note" => :reconciled_note
    }
  end

  def csv_header
    report_hash.keys.join(",") + "\n"
  end

  def order_detail_row(order_detail)
    begin
      report_hash.values.map do |callable|
        result = if callable.is_a?(Symbol)
          order_detail.public_send(callable)
        else
          callable.call(order_detail)
        end

        if result.is_a?(DateTime)
          format_usa_datetime(result)
        else
          result
        end
      end
    rescue => e
      [ "*** ERROR WHEN REPORTING ON ORDER DETAIL #{order_detail}: #{e.message} ***" ]
    end
  end

  def csv_body
    CSVHelper::CSV.generate do |csv|
      report_data.each do |order_detail|
        csv << order_detail_row(order_detail)
      end
    end
  end

  def report_data_query
    Reports::Querier.new(
      order_status_id: @order_status_ids,
      current_facility: @facility,
      date_range_field: @date_range_field,
      date_range_start: date_start,
      date_range_end: date_end,
      includes: [:reservation, :statement],
    ).perform
  end

  def as_currency(number)
    if number.present?
      ActionController::Base.helpers.number_to_currency(number)
    else
      ''
    end
  end

  def canceled_by_name(reservation)
    if reservation.canceled_by == 0
      I18n.t('reports.fields.auto_cancel_name')
    else
      reservation.canceled_by_user.try(:full_name)
    end
  end
end
