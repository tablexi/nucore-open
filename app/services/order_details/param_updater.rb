class OrderDetails::ParamUpdater

  def self.permitted_attributes
    @permitted_attributes ||=
      [
        :account_id,
        :assigned_user_id,
        :resolve_dispute,
        :dispute_resolved_reason,
        :quantity,
        :note,
        reservation: [
          :reserve_start_date,
          :reserve_start_hour,
          :reserve_start_min,
          :reserve_start_meridian,
          :duration_mins,
          :actual_start_date,
          :actual_start_hour,
          :actual_start_min,
          :actual_start_meridian,
          :actual_duration_mins,
        ],
      ]
  end

  def initialize(order_detail, options = {})
    @order_detail = order_detail
    @editing_user = options[:user]
    @options = options
  end

  def assign_attributes(params)
    params = ActionController::Parameters.new(params.try(:dup))
    params.delete(:quantity) unless params[:quantity].to_s =~ /\A\d+\z/

    assign_self_and_reservation_attributes(permitted_params(params))
    # this will overwrite the prices, so if we got cost/subsidy as parameters,
    # we need to use them instead
    assign_policy_and_prices
    @order_detail.assign_attributes(cost_params(params))

    @order_detail
  end

  def update_attributes(params)
    params = params.try(:dup) || {}

    # Assign all the attributes first, and then update the order status.
    # We need to go through update_order_status! so we can cancel the reservation
    # when necessary
    order_status_id = params.delete :order_status_id

    assign_attributes(params)

    @order_detail.transaction do
      @order_detail.reservation.save_as_user(@editing_user) if @order_detail.reservation
      if order_status_id && order_status_id.to_i != @order_detail.order_status_id
        change_order_status(order_status_id, @options[:cancel_fee]) || raise(ActiveRecord::Rollback)
      else
        @order_detail.save_as_user(@editing_user) || raise(ActiveRecord::Rollback)
      end
    end

    merge_reservation_errors if @order_detail.reservation
    is_order_detail_clean
  end

  private

  def cost_params(params)
    params.permit(:actual_cost, :actual_subsidy)
  end

  def permitted_params(params)
    params.permit(*self.class.permitted_attributes)
  end

  def assign_self_and_reservation_attributes(params)
    reservation_attrs = params.delete :reservation
    @order_detail.assign_attributes(params)
    @order_detail.reservation.assign_times_from_params reservation_attrs if @order_detail.reservation && reservation_attrs
  end

  def assign_policy_and_prices
    @order_detail.assign_price_policy(@order_detail.fulfilled_at) if @order_detail.complete?
    @order_detail.assign_estimated_price(nil, @order_detail.fulfilled_at || Time.zone.now) unless @order_detail.price_policy && @order_detail.actual_cost
  end

  def change_order_status(order_status_id, apply_cancel_fee)
    @order_detail.update_order_status! @editing_user,
                                       OrderStatus.find(order_status_id),
                                       admin: true,
                                       apply_cancel_fee: apply_cancel_fee
    true
  rescue => e
    @order_detail.errors.add(:base, :changing_status)
    # returns nil
  end

  def merge_reservation_errors
    @order_detail.reservation.errors.each do |_error, message|
      @order_detail.errors.add("reservation.base", message)
    end
  end

  def is_order_detail_clean
    @order_detail.errors.none? && (@order_detail.reservation.nil? || @order_detail.reservation.errors.none?)
  end

end
