class MessageNotifier
  def initialize(user, ability, facility)
    @user = user
    @ability = ability
    @facility = facility
  end

  def message_count
    notifications.count +
    order_details_in_dispute.count +
    problem_order_details.count +
    problem_reservation_order_details.count +
    training_requests.count
  end

  def messages?
    notifications? ||
    order_details_in_dispute? ||
    problem_order_details? ||
    problem_reservation_order_details? ||
    training_requests?
  end

  def notifications
    (@user.operator? || @user.administrator?) ? @user.notifications.active : []
  end

  def notifications?
    notifications.any?
  end

  def order_details_in_dispute
    return [] unless @ability.can?(:disputed_orders, Facility)
    @facility.try(:order_details_in_dispute) || []
  end

  def order_details_in_dispute?
    order_details_in_dispute.any?
  end

  def problem_order_details
    return [] unless @ability.can?(:show_problems, Order)
    @facility.try(:problem_order_details) || []
  end

  def problem_order_details?
    problem_order_details.any?
  end

  def problem_reservation_order_details
    return [] unless @ability.can?(:show_problems, Reservation)
    @facility.try(:problem_reservation_order_details) || []
  end

  def problem_reservation_order_details?
    problem_reservation_order_details.any?
  end

  def training_requests
    return [] unless @ability.can?(:manage, TrainingRequest)
    @facility.try(:training_requests) || []
  end

  def training_requests?
    training_requests.any?
  end
end
