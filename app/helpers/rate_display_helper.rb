module RateDisplayHelper

  def human_cost_calculation(cost, subsidy)
    cost = 0 if cost.nil?
    subsidy = 0 if subsidy.nil?

    display = if cost > 0 && subsidy > 0
      subsidized_cost_display cost, subsidy
    else
      number_to_currency cost
    end

    display.html_safe
  end

  def subsidized_cost_display(cost, subsidy)
    subsidized_cost = cost * subsidy
    <<-FORMAT
      #{number_to_currency cost}
      <br/>
      -#{number_to_currency subsidized_cost}
      <br/>
      =<b>#{number_to_currency cost-subsidized_cost}</b>
    FORMAT
  end

  def human_rate_calculation(rate, subsidy)
    display = ''

    # handle nil input
    rate    = -1 if rate.nil?
    subsidy = 0 if subsidy.nil?

    # render appropriate string
    if subsidy > 0
      display = subsidized_rate_display rate, subsidy
    elsif rate > -1
      display = non_subsidized_rate_display rate
    end

    display.html_safe
  end


  def non_subsidized_rate_display(rate)
   <<-FORMAT
     #{number_to_currency rate}
     <p class="per-minute-show">#{number_to_currency rate / 60, precision: 4} / minute</p>
   FORMAT
  end


  def subsidized_rate_display(rate, subsidy)
   <<-FORMAT
     #{number_to_currency rate}
     <br/>
     -#{number_to_currency subsidy}
     <br/>
     =<b>#{number_to_currency rate-subsidy}</b>
     <p class="per-minute-show">#{number_to_currency (rate-subsidy) / 60, precision: 4} / minute</p>
   FORMAT
  end

end
