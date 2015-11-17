class FacilityManagement

  def self.register_payment_type(type, options = {})
    options[:short_name] ||= type.name.underscore
    payment_types[type] = options
  end

  private

  def self.payment_types
    @@payment_types ||= {}
  end

end
