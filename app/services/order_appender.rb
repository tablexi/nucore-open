class OrderAppender

  include DateHelper

  attr_reader :original_order, :user

  def initialize(original_order, user)
    @original_order = original_order
    @user = user
  end

  def add!(product, quantity, params)
    products = product.is_a?(Bundle) ? product.products : [product]

    note = params[:note].presence
    fulfilled_at = parse_usa_date(params[:fulfilled_at])
    order_status = load_order_status(params[:order_status_id].presence, product.facility)
    order = products.any?(&:mergeable?) ? build_merge_order : original_order
    order_details = order.add(product, quantity, created_by: user.id)

    notifications = false
    order_details.each do |order_detail|
      order_detail.note = note if note.present?
      order_detail.fulfilled_at = fulfilled_at if fulfilled_at.present?
      order_detail.set_default_status!
      order_detail.change_status!(order_status) if order_status.present?
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

  def build_merge_order
    Order.create!(
      merge_with_order_id: original_order.id,
      facility_id: original_order.facility_id,
      account_id: original_order.account_id,
      user_id: original_order.user_id,
      created_by: user.id,
    )
  end

  def load_order_status(order_status_id, facility)
    OrderStatus.for_facility(facility).find(order_status_id) if order_status_id
  end

end
