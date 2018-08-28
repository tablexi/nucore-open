# frozen_string_literal: true

class CancellationFeeCalculator

  def initialize(reservation)
    @reservation = reservation
  end

  def fee
    @reservation.blank? ? 0 : calculated_fee
  end

  private

  def calculated_fee
    unless defined?(@calculated_fee)
      original_canceled_at = @reservation.order_detail.canceled_at
      @reservation.order_detail.canceled_at = Time.current
      @calculated_fee = @reservation.order_detail.cancellation_fee
      @reservation.order_detail.canceled_at = original_canceled_at
    end

    @calculated_fee
  end

end
