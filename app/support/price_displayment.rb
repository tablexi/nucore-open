#
# Module for use by OrderDetail for easier interface to costs and subsidies
#
# Use:
# order_detail.send(:extend, PriceDisplayment)
# order_detail.display_cost
#
# This will display the actual cost if there is one, otherwise it will fall back to
# estimated price. If there is no estimated price, it'll fall back to a default 'Unassigned'
#
# wrapped_cost will wrap the cost in a span with a class determined by which value
# it's using. E.g. an estimated order detail will have a class of .estimated_cost

module PriceDisplayment
  include ActionView::Helpers::NumberHelper
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
    %(<span class="#{display_cost_class}_cost">#{display_cost}</span>).html_safe
  end

  def wrapped_subsidy
    %(<span class="#{display_cost_class}_cost">#{display_subsidy}</span>).html_safe
  end

  def wrapped_total
    %(<span class="#{display_cost_class}_cost">#{display_total}</span>).html_safe
  end

  def display_cost_class
    if actual_cost
      'actual'
    elsif estimated_cost
      'estimated'
    else
      'unassigned'
    end
  end

private
  def empty_display
    'Unassigned'
  end

  def format(number)
    return unless number
    number_to_currency(number)
  end
end
