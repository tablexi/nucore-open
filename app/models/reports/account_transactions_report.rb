require 'csv'

class Reports::AccountTransactionsReport
  include ApplicationHelper
  include ERB::Util

  def initialize(order_details, options = {})
    @order_details = order_details
    @date_range_field = options[:date_range_field] || 'fulfilled_at'
  end

  def to_csv
    report = []

    report << CSV.generate_line(headers)

    @order_details.each do |od|
      report << CSV.generate_line(build_row(od))
    end

    report.join
  end

  private

  def headers
    [
      Order.model_name.human,
      OrderDetail.model_name.human,
      OrderDetail.human_attribute_name(@date_range_field),
      Facility.model_name.human,
      OrderDetail.human_attribute_name('description'),
      OrderDetail.human_attribute_name('quantity'),
      OrderDetail.human_attribute_name('user'),
      OrderDetail.human_attribute_name('cost'),
      OrderDetail.human_attribute_name('order_status')
    ]
  end

  def build_row(order_detail)
    [
      order_detail.order.id,
      order_detail.id,
      format_usa_date(order_detail.send(:"#{@date_range_field}")),
      order_detail.order.facility,
      order_detail_description(order_detail),
      order_detail_quantity(order_detail),
      order_detail.order.user.full_name,
      order_detail_total(order_detail),
      order_detail.order_status
    ]
  end

  private

  def order_detail_total(order_detail)
    order_detail.send(:extend, PriceDisplayment)
    order_detail.display_total
  end

  def order_detail_quantity(order_detail)
    order_detail.extend PriceDisplayment
    order_detail.quantity_display.value
  end
end
