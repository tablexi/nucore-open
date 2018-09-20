# frozen_string_literal: true

class MoveToProblemQueue

  def self.move!(order_detail, force: false)
    new(order_detail, force: force).move!
  end

  def initialize(order_detail, force: false)
    @order_detail = order_detail
    @force = force
  end

  def move!
    @order_detail.time_data.force_completion = @force
    @order_detail.complete!
    # TODO: Can probably remove this at some point, but it's a safety check for now
    raise "Trying to move Order ##{@order_detail} to problem queue, but it's not a problem" unless @order_detail.problem?
    ProblemOrderMailer.notify_user(@order_detail).deliver_later
  end

end
