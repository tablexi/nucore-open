class OrderPurchaseValidator

  # The AllDetailsOnOrderValidator will validate each individual OrderDetail
  # within the order using the NotePresenceValidator.
  cattr_accessor(:additional_validations) { [AllDetailsOnOrderValidator.build(NotePresenceValidator)] }

  attr_reader :errors

  def initialize(order)
    @order = order
    @errors = []
  end

  def valid?
    additional_validations.all? do |validator_class|
      validator = validator_class.new(@order)
      if validator.valid?
        true
      else
        @errors << validator.error_message
        false
      end
    end
  end

  def invalid?
    !valid?
  end

end
