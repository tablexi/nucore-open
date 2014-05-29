module RateDisplayHelper

  def human_cost_calculation(cost, subsidy)
    cost = 0 if cost.nil?
    subsidy = 0 if subsidy.nil?

    human_cost_calculation_display(cost, subsidy).html_safe
  end

  def human_cost_calculation_display(cost, subsidy)
    if cost > 0 && subsidy > 0
      subsidized_cost_display cost, subsidy
    else
      number_to_currency cost
    end
  end

  def subsidized_cost_display(cost, subsidy)
    subsidized_cost = cost * subsidy
    "#{cost_display cost, subsidized_cost}=#{bold_number_as_currency cost - subsidized_cost}"
  end

  def human_rate_calculation(rate, subsidy)
    # handle nil input
    rate    = -1 if rate.nil?
    subsidy = 0 if subsidy.nil?

    human_rate_calculation_display(rate, subsidy).html_safe
  end

  def human_rate_calculation_display(rate, subsidy)
    case
    when subsidy > 0
      subsidized_rate_display rate, subsidy
    when rate > -1
      "#{number_to_currency rate}#{rate_per_minute_display rate}"
    else
      ''
    end
  end

  def subsidized_rate_display(rate, subsidy)
    "#{cost_display rate, subsidy} =#{bold_number_as_currency rate - subsidy}" \
    " #{rate_per_minute_display rate - subsidy}"
  end

  def cost_display(cost, subsidy)
    <<-FORMAT
      #{number_to_currency cost}
      <br/>
      -#{number_to_currency subsidy}
      <br/>
    FORMAT
  end

  def rate_per_minute_display(rate)
    %(<p class="per-minute-show">#{number_to_currency rate / 60, precision: 4} / minute</p>)
  end

  def bold_number_as_currency(number)
     "<b>#{number_to_currency number}</b>"
  end

end
