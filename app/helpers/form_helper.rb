module FormHelper
  def readonly_form_for(record_name, record = nil, options = {}, &block)
    options, record = record, nil if record.is_a?(Hash) && record.extractable_options?
    record ||= instance_variable_get("@#{record_name}")
    options.merge! :builder => ReadonlyFormBuilder
    simple_fields_for(record_name, record, options, &block)
  end

  def modelless_form_for(options = {}, &block)
    options.merge! :builder => ModelLessFormBuilder
    simple_form_for(options[:object] || '', options, &block)
  end
end
