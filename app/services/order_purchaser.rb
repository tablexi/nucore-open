class OrderPurchaser

  attr_reader :acting_as, :order, :order_in_past, :params, :user
  attr_accessor :backdate_to

  # TODO: remove this once all child instances have been updated
  def self.additional_validations
    warn "Use OrderPurchaseValidator.additional_validations instead of OrderPurchaser at #{caller(1..1)}"
    OrderPurchaseValidator.additional_validations
  end

  alias acting_as? acting_as
  alias order_in_past? order_in_past

  delegate :order_notification_recipient, to: :order

  def initialize(acting_as:, order:, order_in_past:, params:, user:)
    @acting_as = acting_as
    @order = order
    @order_in_past = order_in_past
    @params = params
    @user = user
    @success = false
    @errors = []
  end

  def purchase!
    order_detail_updater.update!
    if order_detail_updater.quantities_changed?
      @errors << I18n.t("controllers.orders.purchase.quantities_changed")
      return
    end

    order.ordered_at = backdate_to if backdate_to

    validate_order!
    return unless do_additional_validations
    purchase_order!

    order_in_the_past! if order_in_past?

    Notifier.delay.order_receipt(user: order.user, order: order) if send_receipt?
    Notifier.delay.order_notification(order, order_notification_recipient) if send_facility_notification?
    @success = true
  rescue NUCore::OrderDetailUpdateException => e
    @errors = order.errors.full_messages
  end

  def success?
    @success
  end

  def errors
    @errors.compact.uniq
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

  def validate_order!
    # Empty because validate_order! and purchase! don't give useful error messages
    raise NUCore::PurchaseException.new("") unless order.validate_order!
  end

  def purchase_order!
    # Empty because validate_order! and purchase! don't give useful error messages
    raise NUCore::PurchaseException.new("") unless order.purchase!
  end

  def do_additional_validations
    validator = OrderPurchaseValidator.new(@order)
    if validator.valid?
      true
    else
      @errors = validator.errors
      false
    end
  end

end
