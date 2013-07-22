class ModelLessFormBuilder < SimpleForm::FormBuilder
  def input(attribute_name, options = {}, &block)
    options.deep_merge! :input_html => { :id => attribute_name, :name => attribute_name }
    super
  end
end
