class OrderAppender

  attr_reader :product, :quantity, :original_order, :user

  def initialize(product, quantity, original_order, user)
    @product = product
    @quantity = quantity
    @order = @original_order = original_order
    @user = user
  end

  def merge?
    products = product.is_a?(Bundle) ? product.products : [product]

    products.any? do |p|
      p.is_a?(Instrument) || (p.is_a?(Service) && (p.active_survey? || p.active_template?))
    end
  end

  def add!
    @order = build_merge_order(@order) if merge?

    begin
      order_details = @order.add(product, quantity, created_by: user.id)
      notifications = false
      order_details.each do |order_detail|
        order_detail.set_default_status!
        if @order.to_be_merged? && !order_detail.valid_for_purchase?
          notifications = true
          MergeNotification.create_for!(user, order_detail)
        end
      end

      notifications
    rescue => e
      Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
      @order.destroy if @order != original_order
      flash[:error] = I18n.t "controllers.facility_orders.update.error", product: product.name
    end
  end

  def build_merge_order(order)
    Order.create!(
      merge_with_order_id: order.id,
      facility_id: order.facility_id,
      account_id: order.account_id,
      user_id: order.user_id,
      created_by: user.id,
    )
  end

end
