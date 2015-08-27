class MessageSummarizer
  class MessageSummary
    attr_reader :count, :controller

    def initialize(count, controller)
      @count = count || 0
      @controller = controller
    end

    def any?
      count > 0
    end

    def link
      controller.view_context.link_to(label, path)
    end

    private

    def facility
      controller.current_facility
    end

    def label
      "#{I18n.t(l18n_key)} (#{count})"
    end
  end

  class Notifications < MessageSummary
    private

    def l18n_key
      "pages.notices"
    end

    def path
      controller.notifications_path
    end
  end

  class OrderDetailsInDispute < MessageSummary
    private

    def l18n_key
      "message_summarizer.order_details_in_dispute"
    end

    def path
      controller.facility_disputed_orders_path(facility)
    end
  end

  class ProblemOrderDetails < MessageSummary
    private

    def l18n_key
      "message_summarizer.problem_order_details"
    end

    def path
      controller.show_problems_facility_orders_path(facility)
    end
  end

  class ProblemReservationOrderDetails < MessageSummary
    private

    def l18n_key
      "message_summarizer.problem_reservation_order_details"
    end

    def path
      controller.show_problems_facility_reservations_path(facility)
    end
  end

  class TrainingRequests < MessageSummary
    private

    def l18n_key
      "message_summarizer.training_requests"
    end

    def path
      controller.facility_training_requests_path(facility)
    end
  end

  def initialize(controller)
    @controller = controller
  end

  def each
    message_summaries.each { |message_summary| yield message_summary }
  end

  def message_count
    message_summaries.sum(&:count)
  end

  def messages?
    message_summaries.any?
  end

  def notifications
    @notifications ||= Notifications.new(notifications_count, @controller)
  end

  def order_details_in_dispute
    @order_details_in_dispute ||=
      OrderDetailsInDispute.new(order_details_in_dispute_count, @controller)
  end

  def problem_order_details
    @problem_order_details ||=
      ProblemOrderDetails.new(problem_order_details_count, @controller)
  end

  def problem_reservation_order_details
    @problem_reservation_order_details ||=
      ProblemReservationOrderDetails.new(
        problem_reservation_order_details_count,
        @controller,
      )
  end

  def training_requests
    @training_requests ||=
      TrainingRequests.new(training_request_count, @controller)
  end

  private

  def ability
    @ability ||= @controller.current_ability
  end

  def facility
    return @facility if defined?(@facility)
    @facility = @controller.current_facility
  end

  def message_summaries
    [
      notifications,
      order_details_in_dispute,
      problem_order_details,
      problem_reservation_order_details,
      training_requests,
    ].select(&:any?)
  end

  def notifications_count
    ((user.operator? || user.administrator?) && user.notifications.active.count)
  end

  def order_details_in_dispute_count
    if facility && ability.can?(:disputed_orders, Facility)
      facility.order_details_in_dispute.count
    end
  end

  def problem_order_details_count
    if facility && ability.can?(:show_problems, Order)
      facility.problem_non_reservation_order_details.count
    end
  end

  def problem_reservation_order_details_count
    if facility && ability.can?(:show_problems, Reservation)
      facility.problem_reservation_order_details.count
    end
  end

  def training_request_count
    if facility && ability.can?(:manage, TrainingRequest)
      facility.training_requests.count
    end
  end

  def user
    @user ||= @controller.current_user
  end
end
