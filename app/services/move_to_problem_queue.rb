# frozen_string_literal: true

class MoveToProblemQueue

  def self.move!(order_detail)
    new(order_detail).move!
  end

  def initialize(order_detail)
    @order_detail = order_detail
  end

  def move!
    @order_detail.complete!
    # TODO: Can probably remove this at some point, but it's a safety check for now
    raise "Trying to move Order ##{@order_detail} to problem queue, but it's not a problem" unless @order_detail.problem?
    ProblemOrderMailer.notify_user(@order_detail).deliver_later
  end

end
