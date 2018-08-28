# frozen_string_literal: true

class OrderAppender

  include DateHelper

  attr_reader :original_order, :user

  def initialize(original_order, user)
    @original_order = original_order
    @user = user
  end

  def add!(product, quantity, params)
    OrderDetail.transaction do
      products = product.is_a?(Bundle) ? product.products : [product]
      order_status = load_order_status(params[:order_status_id].presence, product.facility)
      order = products.any?(&:mergeable?) ? build_merge_order : original_order
      notifications = false

      attributes = {
        note: params[:note].presence,
        duration: params[:duration],
        created_by: user.id,
      }

      order.add(product, quantity, attributes).each do |order_detail|
        update_order_detail!(order_detail, order_status: order_status, fulfilled_at: params[:fulfilled_at])

        if order.to_be_merged? && !order_detail.valid_for_purchase?
          notifications = true
          MergeNotification.create_for!(user, order_detail)
        end
      end

      notifications
    end
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

  def update_order_detail!(order_detail, order_status:, fulfilled_at:)
    order_detail.manual_fulfilled_at = fulfilled_at
    order_detail.set_default_status!
    order_detail.change_status!(order_status) if order_status.present?
  end

end
