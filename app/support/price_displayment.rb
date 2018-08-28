# frozen_string_literal: true

#
# Module for use by OrderDetail for easier interface to costs and subsidies
#
# Use:
# order_detail.send(:extend, PriceDisplayment) <-- deprecated in favor of using OrderDetailPresenter
# order_detail.display_cost
#
# This will display the actual cost if there is one, otherwise it will fall back to
# estimated price. If there is no estimated price, it'll fall back to a default 'Unassigned'
#
# wrapped_cost will wrap the cost in a span with a class determined by which value
# it's using. E.g. an estimated order detail will have a class of .estimated_cost

module PriceDisplayment

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TagHelper

  def display_cost
    format(actual_cost) || format(estimated_cost) || empty_display
  end

  def display_subsidy
    return unless has_subsidies?
    format(actual_subsidy) || format(estimated_subsidy) || empty_display
  end

  def display_total
    format(actual_total) || format(estimated_total) || empty_display
  end

  def wrapped_cost
    content_tag :span, display_cost, class: "#{display_cost_class}_cost"
  end

  def wrapped_subsidy
    content_tag :span, display_subsidy, class: "#{display_cost_class}_cost"
  end

  def wrapped_total
    content_tag :span, display_total, class: "#{display_cost_class}_cost"
  end

  def display_cost_class
    if actual_cost
      "actual"
    elsif estimated_cost
      "estimated"
    else
      "unassigned"
    end
  end

  def actual_cost?
    actual_cost.present?
  end

  class QuantityDisplay < Struct.new(:value)

    def html
      value
    end

    def csv
      value.to_s
    end

  end

  class TimeQuantityDisplay < QuantityDisplay

    include ActionView::Helpers::TagHelper

    def csv
      # equal sign and quotes prevent Excel from formatting as a date/time
      %(="#{MinutesToTimeFormatter.new(value)}")
    end

    def html
      MinutesToTimeFormatter.new(value).to_s
    end

  end

  def build_quantity_presenter
    if time_data.try(:actual_duration_mins) && time_data.actual_duration_mins.to_i > 0
      TimeQuantityDisplay.new(time_data.actual_duration_mins)
    elsif time_data.try(:duration_mins)
      TimeQuantityDisplay.new(time_data.duration_mins)
    elsif quantity_as_time?
      TimeQuantityDisplay.new(quantity)
    else
      QuantityDisplay.new(quantity)
    end
  end

  def display_quantity
    build_quantity_presenter.value
  end

  def wrapped_quantity
    build_quantity_presenter.html
  end

  def csv_quantity
    build_quantity_presenter.csv
  end

  private

  def empty_display
    "Unassigned"
  end

  def format(number)
    return unless number
    number_to_currency(number)
  end

end
