module TimeData

  def self.for(order_detail)
    "#{self}::#{order_detail.product.type}Presenter".constantize.new(order_detail)
  rescue NameError => e
    # noop, return nil
  end

end
