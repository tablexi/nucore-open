class ReadonlyInput < SimpleForm::Inputs::Base
  include DateHelper

  disable :required

  def input

    template.content_tag :div, :class => 'readonly' do
      value = object.send(attribute_name)
      value = process_datetime(value) if value.class <= ActiveSupport::TimeWithZone
      value.send(options[:value_method] || :to_s)
    end
  end

  private

  def process_datetime(value)
    human_datetime(value, options.slice(:date_only))
  end

end
