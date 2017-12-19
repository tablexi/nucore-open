class TransactionChosen2Input < SimpleForm::Inputs::CollectionInput

  disable :required

  def input(wrapper_options = nil)
    label_method, value_method = detect_collection_methods

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    # By calling `to_a` here, it fetches the AR::Relation into objects. Since that will
    # happen later anyways, by doing it up front, we prevent extra `count(*)` queries,
    # which were slowing down the page.
    collection_size = collection.to_a.size

    merged_input_options[:multiple] = true
    merged_input_options["data-placeholder"] = placeholder_label

    # If there is only one possible value, then we want to show it, and not allow
    # selection, but only if it's not a nullable field
    if collection_size == 1 && !options[:allow_blank]
      # TODO: what about this?
      # search_fields[attribute_name] = [collection.first.public_send(value_method)]
      collection.shift
      merged_input_options[:disabled] = :disabled
    end

    @builder.collection_select(
      attribute_name, collection, value_method, label_method,
      input_options, merged_input_options
    )
  end

  def label(wrapper_options)
    options[:label] ||= model_label
    super
  end

  private

  def model_label
    attribute_class.model_name.human(count: 2)
  rescue
    attribute_name
  end

  def attribute_class
    attribute_name.to_s.classify.constantize
  # rescue
  #   attribute_name
  end

  def placeholder_label
    "Select #{options[:label].downcase}"
  end

end
