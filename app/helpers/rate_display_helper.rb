module RateDisplayHelper

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
