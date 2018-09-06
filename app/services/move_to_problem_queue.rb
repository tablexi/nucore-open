# frozen_string_literal: true

class MoveToProblemQueue

  def self.move!(order_detail)
    new(order_detail).move!
  end

  def initialize(order_detail)
    @order_detail = order_detail
  end

  def move!
    @order_detail.force_complete!
    raise "It's not a problem!" unless @order_detail.problem? # TODO: Remove me
  end

end
