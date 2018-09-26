# frozen_string_literal: true

class CancellationFeeCalculator

  attr_accessor :reservation
  delegate :order_detail, to: :reservation

  def initialize(reservation)
    @reservation = reservation
  end

  def fee
    reservation.blank? ? 0 : calculated_fee
  end

  private

  def calculated_fee
    unless defined?(@calculated_fee)
      order_detail.canceled_at = Time.current
      @calculated_fee = order_detail.cancellation_fee
      # OrderDetail#cancellation_fee updates the actual costs. Now reset everything.
      order_detail.reload
    end

    @calculated_fee
  end

end
