class ValidatorFactory

  @@validator_class=Settings.validator.class_name.constantize


  def self.instance(*args)
    @@validator_class.new(*args)
  end


  #
  # Make it easy to query the validator class through the factory
  #

  def self.method_missing(method_sym, *arguments, &block)
    @@validator_class.send(method_sym, *arguments, &block)
  end


  def self.respond_to?(method_sym, include_private = false)
    @@validator_class.respond_to? method_sym, include_private
  end
end