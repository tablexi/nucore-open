class OrderAppender

  attr_reader :fulfilled_at, :note, :order_status_id, :original_order, :product,
              :quantity, :user

  def initialize(product:, quantity:, original_order:, user:, note: nil, fulfilled_at: nil, order_status_id: nil)
    @product = product
    @quantity = quantity
    @original_order = original_order
    @user = user
    @note = note
    @fulfilled_at = fulfilled_at
    @order_status_id = order_status_id
  end

  def add!
    notifications = false
    order_details.each do |order_detail|
      order_detail.note = note if note.present?
      order_detail.fulfilled_at = fulfilled_at if fulfilled_at.present?
      order_detail.set_default_status!
      order_detail.change_status!(order_status) if order_status_id.present?
      if order.to_be_merged? && !order_detail.valid_for_purchase?
        notifications = true
        MergeNotification.create_for!(user, order_detail)
      end
    end

    notifications
  rescue => e
    order.destroy if order != original_order
    raise e
  end

  private

  def order
    @order ||= merge? ? build_merge_order : original_order
  end

  def order_details
    @order_details ||= order.add(product, quantity, created_by: user.id)
  end

  def build_merge_order
    Order.create!(
      merge_with_order_id: original_order.id,
      facility_id: original_order.facility_id,
      account_id: original_order.account_id,
      user_id: original_order.user_id,
      created_by: user.id,
    )
  end

  def merge?
    products.any? do |product|
      product.is_a?(Instrument) ||
        (product.is_a?(Service) && (product.active_survey? || product.active_template?))
    end
  end

  def order_status
    @order_status ||=
      OrderStatus.for_facility(product.facility).find(order_status_id)
  end

  def products
    @products ||= product.is_a?(Bundle) ? product.products : [product]
  end

end
