class OrderDetailListTransformerFactory

  @@klass = Settings.order_details.list_transformer.constantize

  def self.instance(*args)
    @@klass.new(*args)
  end

end
