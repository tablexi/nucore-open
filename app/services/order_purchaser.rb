class OrderPurchaser

  attr_reader :acting_as, :order, :order_in_past, :params, :user
  alias acting_as? acting_as
  alias order_in_past? order_in_past

  delegate :order_notification_recipient, to: :order
  delegate :quantities_changed?, to: :order_detail_updater

  def initialize(acting_as:, order:, order_in_past:, params:, user:)
    @acting_as = acting_as
    @order = order
    @order_in_past = order_in_past
    @params = params
    @user = user
  end

  def purchase!
    return if order_detail_updater.update! && quantities_changed?

    validate_and_purchase!
    order_in_the_past! if order_in_past?

    Notifier.delay.order_receipt(user: order.user, order: order) if send_receipt?
    Notifier.delay.order_notification(order, order_notification_recipient) if send_facility_notification?
  end

  private

  def order_detail_updater
    @order_detail_updater ||= OrderDetailUpdater.new(order, order_update_params)
  end

  def order_in_the_past!
    unless order.can_backdate_order_details?
      raise NUCore::PurchaseException.new(I18n.t("controllers.orders.purchase.future_dating_error"))
    end

    # update order detail statuses if you've changed it while acting as
    if acting_as? && order_status_id.present?
      order.backdate_order_details!(user, order_status_id)
    else
      order.complete_past_reservations!
    end
  end

  def order_status_id
    params[:order_status_id]
  end

  def order_update_params
    @order_update_params ||= OrderDetailUpdateParamHashExtractor.new(params).to_h
  end

  def quantities
    order.order_details.order("order_details.id").pluck(:quantity)
  end

  def send_facility_notification?
    order_notification_recipient.present? && !acting_as?
  end

  def send_receipt?
    !acting_as? || params[:send_notification] == "1"
  end

  def validate_and_purchase!
    unless order.validate_order! && order.purchase!
      # Empty because validate_order! and purchase! don't give useful error messages
      raise NUCore::PurchaseException.new("")
    end
  end

end
