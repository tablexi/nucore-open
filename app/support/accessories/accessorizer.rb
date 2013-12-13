class Accessories::Accessorizer
  def initialize(order_detail)
    @order_detail = order_detail
  end

  def add_accessory(accessory, options = {})
    new_order_detail = build_accessory_order_detail(accessory, options)
    make_order_detail_complete(new_order_detail)
    new_order_detail
  end

  def build_accessory_order_detail(accessory, options = {})
    return nil unless valid_accessory?(accessory)
    od = @order_detail.child_order_details.build(detail_attributes(accessory, options))
    decorated_od = decorate(od)
    decorated_od.update_quantity
    decorated_od
  end

  def update_children
    changed = []
    # TODO skip statemented/journaled order details?
    @order_detail.child_order_details.each do |od|
      update_child_detail(od)
      changed << od if od.changed?
      od.save
    end
    changed
  end

  # Returns the accessories for the product, but excludes all the accessories that
  # have already been ordered
  def available_accessory_order_details
    current_accessories = @order_detail.child_order_details.map(&:product)
    accessories = @order_detail.product.accessories.reject { |a| current_accessories.include? a }
    accessories.map { |a| self.build_accessory_order_detail(a) }
  end

  def add_from_params(params)
    result = []
    params = params.to_hash.stringify_keys # make sure integer keys get converted to strings

    params.select! { |product_id, product_params| ['true', '1'].include? product_params[:enabled] }

    @order_detail.transaction do
      result = available_accessory_order_details.collect do |od|
        update_order_detail_from_params(od, params)
      end

      raise ActiveRecord::Rollback if result.any? { |od| od.errors.any? }
    end
    result
  end

  private

  def product_accessory(accessory)
    @order_detail.product.product_accessories.where(:accessory_id => accessory.id).first
  end

  def valid_accessory?(accessory)
    @order_detail.product.accessories.include? accessory
  end

  def decorate(order_detail)
    Accessories::Scaling.decorate(order_detail)
  end

  def update_child_detail(od)
    decorated_od = decorate(od)
    od.account = @order_detail.account
    decorated_od.update_quantity
    od.assign_actual_price
  end

  def update_order_detail_from_params(od, params)
    product_id = od.product_id.to_s
    if params[product_id] && params[product_id][:enabled]
      od.assign_attributes(params[product_id])
      make_order_detail_complete(od)
    end
    od
  end

  def make_order_detail_complete(od)
    od.update_quantity
    # save first so state/status are set before marking complete
    od.backdate_to_complete! if od.save
  end

  def detail_attributes(accessory, options)
    attrs = @order_detail.attributes.slice('order_id', 'account_id', 'created_by')
    attrs.merge({
      :product  => accessory,
      :quantity => options[:quantity],
      :product_accessory => product_accessory(accessory)
    })
  end
end
