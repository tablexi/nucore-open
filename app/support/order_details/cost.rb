class OrderDetails::Cost
  include ActionView::Helpers::NumberHelper

  def initialize(order_details)
    @order_details = order_details
  end

  def final_total
    @order_details.sum { |d| d.total || 0 }
  end

  def display_final_total
    format(final_total)
  end

  def format(number)
    return unless number
    number_to_currency(number)
  end
end
