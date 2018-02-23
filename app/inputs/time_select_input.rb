class TimeSelectInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    output = ActiveSupport::SafeBuffer.new
    output << select_tag("#{attribute_name}[hour]", options_for_select(hour_options, value.strftime("%I").to_i))
    output << select_tag("#{attribute_name}[minute]", options_for_select(minute_options, value.min))
    output << select_tag("#{attribute_name}[ampm]", options_for_select(%w(AM PM), value.strftime("%p")))
    output.html_safe
  end

  private

  def minute_options(step = nil)
    step ||= 5
    (0..59).step(step).map { |d| ["%02d" % d, d] }
  end

  def hour_options
    (1..12).map { |x| [x, x] }
  end
end
