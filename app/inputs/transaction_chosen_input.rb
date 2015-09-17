class TransactionChosenInput < SimpleForm::Inputs::Base #CollectionSelectInput
  disable :required

  def input
    options[:label_method] ||= :name
    options[:value_method] ||= :id

    # By calling `to_a` here, it fetches the AR::Relation into objects. Since that will
    # happen later anyways, by doing it up front, we prevent extra `count(*)` queries,
    # which were slowing down the page.
    collection_size = collection_items.to_a.size

    search_fields[attribute_name] = [collection_items.first.send(options[:value_method].to_sym)] if collection_size == 1

    select_options = {:multiple => true, :"data-placeholder" => placeholder_label }
    select_options.merge!({:disabled => :disabled}) unless collection_size > 1

    template.select_tag(attribute_name, option_data, select_options).html_safe
  end

  def label
    options[:label] ||= model_label
    super
  end

  private

  def collection_items
    template.instance_variable_get("@#{attribute_name}")
  end

  def model_label
    attribute_class.model_name.human(:count => 2)
  end

  def search_fields
    template.instance_variable_get("@search_fields")
  end

  def attribute_class
    attribute_name.to_s.classify.constantize
  end

  def placeholder_label
    "Select #{options[:label].downcase}"
  end

  def option_data
    if options[:data_method]
      template.send(options[:data_method], collection_items, search_fields[attribute_name])
    else
      template.options_from_collection_for_select(collection_items, options[:value_method], options[:label_method], search_fields[attribute_name])
    end
  end
end
