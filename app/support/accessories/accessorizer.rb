class Accessories::Accessorizer
  def initialize(order_detail)
    @order_detail = order_detail
  end

  def add_accessory(accessory, options = {})
    new_order_detail = build_accessory_order_detail(accessory, options)
    new_order_detail.to_complete!
    new_order_detail
  end

  def build_accessory_order_detail(accessory, options = {})
    result = @order_detail.child_order_details.build(detail_attributes(accessory, options))
  end

  def update_children
    # TODO skip statemented/journaled order details?
    @order_detail.child_order_details.each do |od|
      od.account = @order_detail.account
      od.quantity = updated_quantity(od.product)
      od.assign_actual_price
      od.save
    end
  end

  private

  def default_quantity(accessory)
    quantity_builder(accessory).default_quantity
  end

  def updated_quantity(accessory)
    quantity_builder(accessory).updated_quantity
  end

  def product_accessory(accessory)
    accessory = ProductAccessory.where(:product_id => @order_detail.product.id, :accessory_id => accessory.id).first
    accessory.send(:extend, Accessories::Scaling)
    accessory
  end

  def quantity_builder(accessory)
    product_accessory(accessory).quantity_builder(@order_detail)
  end

  def detail_attributes(accessory, options)
    attrs = @order_detail.attributes.slice('order_id', 'account_id', 'created_by')
    attrs.merge({
      :product  => accessory,
      :quantity => (default_quantity(accessory) || options[:quantity] || 1).to_i
    })
  end
end
