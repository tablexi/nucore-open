module TimeData

  def self.for(order_detail)
    "#{self}::#{order_detail.product.type}Data".constantize.new(order_detail).time_data
  rescue NameError => e
    # noop, return nil
  end

end
