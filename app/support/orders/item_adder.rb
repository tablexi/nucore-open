class Orders::ItemAdder
  def initialize(order)
    @order = order
  end

  def add(product, quantity = 1)
    check_for_mixed_facility! product
    @quantity = quantity.to_i
    return [] if quantity <= 0

    if product.is_a? Bundle
      ods = add_bundles(product, @quantity)
    elsif product.is_a? Service
      ods = add_services(product, @quantity)
    # products which have reservations (instruments) should each get their own order_detail
    elsif (product.respond_to?(:reservations) and quantity > 1) then
      ods = add_instruments(product, @quantity)
    else
      ods = [create_order_detail(:product_id => product.id, :quantity => @quantity)]
    end
    ods || []
  end

private
  def check_for_mixed_facility!(product)
    if product.facility != @order.facility
      if @order.order_details.length > 0
        raise NUCore::MixedFacilityCart
      else
        @order.update_attributes(:facility => product.facility)
      end
    end
  end

  def add_instruments(product, quantity)
    quantity.times.collect do
      create_order_detail(:product_id => product.id, :quantity => 1)
    end
  end

  def add_services(product, quantity)
    separate = (product.active_template? || product.active_survey?)
    # can't add single order_detail for service when it requires a template or a survey.
    # number of order details to add
    repeat = separate ? quantity : 1
    # quantity to add them with
    individual_quantity = separate ? 1 : quantity

    repeat.times.collect do
      create_order_detail(:product_id => product.id, :quantity => individual_quantity)
    end
  end

  def add_bundles(product, quantity)
    quantity.times.inject([]) { |ods| ods.concat create_bundle_order_detail(product) }
  end

  def create_bundle_order_detail(product)
    group_id = @order.max_group_id + 1
    product.bundle_products.collect do |bp|
      create_order_detail(
        :product_id => bp.product.id,
        :quantity => bp.quantity,
        :bundle_product_id => product.id,
        :group_id => group_id)
    end
  end

  def create_order_detail(options)
    options.reverse_merge!(
      :quantity => 1,
      :account => @order.account,
      :created_by => @order.created_by
      )
    @order.order_details.create!(options)
  end

end