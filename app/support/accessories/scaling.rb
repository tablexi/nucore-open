module Accessories::Scaling
  def quantity_builder(order_detail)
    case scaling_type
    when 'manual'
      Manual.new(order_detail)
    when 'auto'
      Auto.new(order_detail)
    else
      Default.new(order_detail)
    end
  end
end
