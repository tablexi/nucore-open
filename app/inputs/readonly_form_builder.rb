class ReadonlyFormBuilder < SimpleForm::FormBuilder
  def input(attribute_name, options = {}, &block)
    options[:as] = :readonly
    super
  end
end
