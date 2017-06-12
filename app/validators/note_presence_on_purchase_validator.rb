class NotePresenceOnPurchaseValidator

  def initialize(order)
    @order = order
  end

  def valid?
    # Use select instead of none? to make sure we loop over everything
    invalid_orders = @order.order_details.select do |od|
      if od.product.user_notes_field_mode.required? && od.note.blank?
        od.errors.add(:note, :blank) # truthy return
      end
    end

    invalid_orders.none?
  end

  def error_message
    "Some products require notes"
  end

end
