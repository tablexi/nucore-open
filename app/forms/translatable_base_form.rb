class TranslatableBaseForm < SimpleDelegator

  extend ActiveModel::Translation

  def self.for(instance)
    instance_class = instance.class
    # Dynamically create a subclass where the model_name is based off the original
    # instance's type so that `human_attribute_name` can work off the same translations
    # as the original object.
    Class.new(self) do
      # This will be a class method, i.e. def self.model_name
      define_singleton_method(:model_name) do
        ActiveModel::Name.new(instance_class)
      end

      define_singleton_method(:i18n_scope) do
        instance_class.i18n_scope
      end

      # So I18n looks upwards in the class hierarchy
      define_singleton_method(:ancestors) do
        instance_class.ancestors
      end

      # SimpleForm needs to recognize this method
      define_singleton_method(:reflect_on_association) do |*args|
        instance_class.reflect_on_association(*args)
      end
    end.new(instance)
  end

    def model_name
      ActiveModel::Name.new(__getobj__.class)
    end

    def to_model
      self
    end

end
