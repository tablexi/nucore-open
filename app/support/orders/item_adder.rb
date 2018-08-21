# frozen_string_literal: true

class Orders::ItemAdder

  # timed services default to 1 minute (arbitrary)
  DEFAULT_TIMED_SERVICES_DURATION = 1

  def initialize(order)
    @order = order
  end

  def add(product, quantity = 1, attributes = {})
    check_for_mixed_facility! product
    quantity = quantity.to_i
    # Only TimedServices care about duration
    duration = attributes.delete(:duration)

    return [] if quantity <= 0

    ods = if product.is_a? Bundle
            add_bundles(product, quantity, attributes)
          elsif product.is_a? Service
            add_services(product, quantity, attributes)
          elsif product.is_a? TimedService
            add_timed_services(product, quantity, duration, attributes)
          elsif product.respond_to?(:reservations) && quantity > 1
            # products which have reservations (instruments) should each get their own order_detail
            add_instruments(product, quantity, attributes)
          else
            [create_order_detail({ product_id: product.id, quantity: quantity }.merge(attributes))]
          end
    ods || []
  end

  private

  def check_for_mixed_facility!(product)
    if product.facility != @order.facility
      if @order.order_details.length > 0
        raise NUCore::MixedFacilityCart
      else
        @order.update_attributes(facility: product.facility)
      end
    end
  end

  def add_instruments(product, quantity, attributes)
    Array.new(quantity) do
      create_order_detail({ product_id: product.id, quantity: 1 }.merge(attributes))
    end
  end

  def add_timed_services(product, quantity, duration, attributes)
    Array.new(quantity) do
      create_order_detail({ product_id: product.id, quantity: duration || DEFAULT_TIMED_SERVICES_DURATION }.merge(attributes))
    end
  end

  def add_services(product, quantity, attributes)
    separate = (product.active_template? || product.active_survey?)
    # can't add single order_detail for service when it requires a template or a survey.
    # number of order details to add
    repeat = separate ? quantity : 1
    # quantity to add them with
    individual_quantity = separate ? 1 : quantity

    Array.new(repeat) do
      create_order_detail({ product_id: product.id, quantity: individual_quantity }.merge(attributes))
    end
  end

  def add_bundles(product, quantity, attributes = {})
    quantity.times.inject([]) { |ods, _i| ods.concat create_bundle_order_detail(product, attributes) }
  end

  def create_bundle_order_detail(product, attributes = {})
    group_id = @order.max_group_id + 1
    product.bundle_products.collect do |bp|
      create_order_detail(
        {
          product_id: bp.product.id,
          quantity: bp.quantity,
          bundle_product_id: product.id,
          group_id: group_id,
        }.merge(attributes),
      )
    end
  end

  def create_order_detail(options)
    options.reverse_merge!(
      quantity: 1,
      account: @order.account,
      created_by: @order.created_by,
    )
    @order.order_details.create!(options)
  end

end
