class OrderDetailQuantityInput < SimpleForm::Inputs::FileInput

  def input
    input_html_options[:class] << 'timeinput' if object.quantity_as_time?
    @builder.text_field(attribute_name, input_html_options).html_safe
  end

  def hint
    if object.scaling_type && !object.quantity_editable?
      @hint ||= I18n.t("product_accessories.type.#{object.scaling_type}")
    end
  end

  private

  def has_disabled?
    !object.quantity_editable?
  end
end
