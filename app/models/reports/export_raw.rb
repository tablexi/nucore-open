require 'csv'
class Reports::ExportRaw
  include DateHelper

  attr_reader :order_status_ids, :facility, :date_range_field

  def self.transformers
    @@transformers ||= []
  end

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

  def column_headers
    report_hash.keys.map do |key|
      I18n.t("controllers.general_reports.headers.#{key}")
    end
  end

  private

  def report_hash
    transformers.reduce(default_report_hash) do |result, class_name|
      class_name.constantize.new.transform(result)
    end
  end

  def transformers
    self.class.transformers
  end

  def default_report_hash
    {
      facility: :facility,
      order: :to_s,
      ordered_at: -> (od) { od.order.ordered_at },
      fulfilled_at: -> (od) { od.fulfilled_at },
      order_status: -> (od) { od.order_status.name },
      order_state: :state,
      ordered_by: -> (od) { od.order.created_by_user.username },
      first_name: -> (od) { od.order.created_by_user.first_name },
      last_name: -> (od) { od.order.created_by_user.last_name },
      email: -> (od) { od.order.created_by_user.email },
      purchaser: -> (od) { od.order.user.username },
      purchaser_first_name: -> (od) { od.order.user.first_name },
      purchaser_last_name: -> (od) { od.order.user.last_name },
      purchaser_email: -> (od) { od.order.user.email },
      product_id: -> (od) { od.product.url_name },
      product_type: -> (od) { od.product.type.underscore.humanize },
      product: -> (od) { od.product.name },
      quantity: :quantity,
      bundled_products: -> (od) { od.product.is_a?(Bundle) ? od.product.products.collect(&:name).join(' & ') : nil },
      account_type: -> (od) { od.account.type.underscore.humanize },
      affiliate: -> (od) { od.account.affiliate_to_s },
      account: -> (od) { od.account.account_number },
      account_description: -> (od) { od.account.description_to_s },
      account_expiration: -> (od) { od.account.expires_at },
      account_owner: -> (od) { od.account.owner_user.username },
      owner_first_name: -> (od) { od.account.owner_user.first_name },
      owner_last_name: -> (od) { od.account.owner_user.last_name },
      owner_email: -> (od) { od.account.owner_user.email },
      price_group: -> (od) { od.price_policy.try(:price_group).try(:name) },
      estimated_cost: -> (od) { as_currency(od.estimated_cost) },
      estimated_subsidy: -> (od) { as_currency(od.estimated_subsidy) },
      estimated_total: -> (od) { as_currency(od.estimated_total) },
      actual_cost: -> (od) { as_currency(od.actual_cost) },
      actual_subsidy: -> (od) { as_currency(od.actual_subsidy) },
      actual_total: -> (od) { as_currency(od.actual_total) },
      reservation_start_time: -> (od) { od.reservation.reserve_start_at if od.reservation },
      reservation_end_time: -> (od) { od.reservation.reserve_end_at if od.reservation },
      reservation_minutes: -> (od) { od.reservation.try(:duration_mins) },
      actual_start_time: -> (od) { od.reservation.actual_start_at if od.reservation },
      actual_end_time: -> (od) { od.reservation.actual_end_at if od.reservation },
      actual_minutes: -> (od) { od.reservation.try(:actual_duration_mins) },
      canceled_at: -> (od) { od.reservation.canceled_at if od.reservation },
      canceled_by: -> (od) { canceled_by_name(od.reservation) if od.reservation },
      note: :note,
      disputed_at: -> (od) { od.dispute_at },
      dispute_reason: :dispute_at,
      dispute_resolved_at: -> (od) { od.dispute_resolved_at },
      dispute_resolved_reason: :dispute_resolved_reason,
      reviewed_at: -> (od) { od.reviewed_at },
      statemented_on: -> (od) { od.statement.created_at if od.statement },
      journal_date: -> (od) { od.journal.journal_date if od.journal },
      reconciled_note: :reconciled_note,
    }
  end

  def csv_header
    column_headers.join(",") + "\n"
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
