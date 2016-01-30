module Converters
  class ConverterFactory

    attr_accessor :account_type

    def initialize(options = {})
      @account_type = options[:account].class.to_s.underscore if options[:account]
      @account_type ||= "default"
    end

    def for(converter_type)
      begin
        Settings.converters[account_type][converter_type].constantize
      rescue NameError, NoMethodError
        Settings.converters["default"][converter_type].constantize
      end
    end

  end
end
