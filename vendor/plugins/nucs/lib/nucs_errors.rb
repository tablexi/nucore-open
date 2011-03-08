module NucsErrors

  #
  # Base class for all nucs related errors.
  # Makes it easier to write rescues.
  class NucsError < StandardError; end


  #
  # Raised when there is an import parsing error
  class ImportError < NucsError
    def initialize(message='malformed line')
      super(message)
    end
  end


  #
  # Raised when user input is invalid
  class InputError < NucsError
    def initialize(input_name, input)
      super("#{input} is invalid for #{input_name}")
    end
  end


  #
  # Raised when user input is invalid and commonly transposed with a valid value
  class TranspositionError < NucsError
    def initialize(was, might_be)
      super("#{was} given, should it be #{might_be}?")
    end
  end


  #
  # Raised for chart string components that are not found in the GE001 tables
  class UnknownGE001Error < NucsError
    def initialize(component, value)
      super("#{value} is GE001 invalid for #{component}")
    end
  end


  #
  # Raised for chart string components that are not found in the GL066 tables
  class UnknownGL066Error < NucsError
    def initialize(component, value=nil)
      if value
        super("#{value} is not allowed for #{component}")
      elsif component.is_a?(Hash)
        msg=[]
        component.each{|k, v| msg << "#{k.to_s} is #{v}" }
        super("could not find a GL066 value where #{msg.to_sentence}")
      else
        super()
      end
    end
  end


  #
  # Raised when a chart string references a valid GL066 budgeted chart
  # string, but that chart string is expired
  class DatedGL066Error < NucsError; end


  #
  # Raised when an account is searched for but not found in the GrantsBudgetTree
  class UnknownBudgetTreeError < NucsError
    def initialize(account)
      super("account #{account} not found in Grants Budget Tree")
    end
  end
end