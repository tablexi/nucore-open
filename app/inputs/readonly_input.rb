class ReadonlyInput < SimpleForm::Inputs::Base
  include DateHelper

  disable :required

  def input

    classes = [*input_html_options[:class]]
    template.content_tag :div, :class => classes do
      value = input_html_options[:value] || object.send(attribute_name)
      value = process_datetime(value) if value.class <= ActiveSupport::TimeWithZone
      value = process_boolean(value)  if !!value == value # is it a boolean
      value = options.delete(:value_method).call(value) if options[:value_method].is_a?(Proc)
      value = value.send(options[:value_method] || :to_s)
      value.to_s.presence || options[:default_value] #extra to_s is in case value is integer 0
    end
  end

  private

  def process_datetime(value)
    human_datetime(value, options.slice(:date_only))
  end

  def process_boolean(value)
    value ? I18n.t('boolean.true') : I18n.t('boolean.false')
  end

end
