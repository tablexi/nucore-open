# frozen_string_literal: true

class CancellationFeeCalculator

  attr_accessor :order_detail
  delegate :reservation, :product, :price_policy, to: :order_detail, allow_nil: true

  def initialize(order_detail)
    # Use a dupped version so that any changes don't get applied to the original
    @order_detail = order_detail.dup
    @order_detail.time_data = order_detail.time_data.dup
  end

  def fee
    return 0 unless reservation && product.min_cancel_hours.to_i > 0

    return @fee if defined?(@fee)
    order_detail.canceled_at = Time.current
    order_detail.assign_price_policy
    @fee = order_detail.actual_cost.to_f
  end

  def charge_full_price?
    fee # make sure fee has been initialized in case this gets called first
    order_detail.price_policy&.charge_full_price_on_cancellation?
  end

end
