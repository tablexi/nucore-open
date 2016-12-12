class CancellationFeeCalculator

  def initialize(reservation)
    @reservation = reservation
  end

  def fee
    @reservation.blank? ? 0 : calculated_fee
  end

  private

  def calculated_fee
    if @calculated_fee.blank?

      # This is wrapped in a transaction and rolled back because
      # #cancellation_fee can reassign price policies and costs.
      @reservation.class.transaction do
        @reservation.canceled_at = Time.current
        @calculated_fee = @reservation.order_detail.cancellation_fee
        raise ActiveRecord::Rollback
      end
    end

    @calculated_fee
  end

end
