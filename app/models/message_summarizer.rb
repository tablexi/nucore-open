class MessageSummarizer
  class MessageSummary
    attr_reader :controller

    def initialize(controller)
      @controller = controller
    end

    def any?
      count > 0
    end

    def count
      @count ||= allowed? ? get_count : 0
    end

    def link
      controller.view_context.link_to(label, path)
    end

    private

    def ability
      controller.current_ability
    end

    def facility
      controller.current_facility
    end

    def label
      "#{I18n.t(l18n_key)} (#{count})"
    end
  end

  class Notifications < MessageSummary
    private

    def allowed?
      user.operator? || user.administrator?
    end

    def get_count
      user.notifications.active.count
    end

    def l18n_key
      "pages.notices"
    end

    def path
      controller.notifications_path
    end

    def user
      @user ||= controller.current_user
    end
  end

  class OrderDetailsInDispute < MessageSummary
    private

    def allowed?
      facility && ability.can?(:disputed_orders, Facility)
    end

    def get_count
      facility.order_details_in_dispute.count
    end

    def l18n_key
      "message_summarizer.order_details_in_dispute"
    end

    def path
      controller.facility_disputed_orders_path(facility)
    end
  end

  class ProblemOrderDetails < MessageSummary
    private

    def allowed?
      facility && ability.can?(:show_problems, Order)
    end

    def get_count
      facility.problem_non_reservation_order_details.count
    end

    def l18n_key
      "message_summarizer.problem_order_details"
    end

    def path
      controller.show_problems_facility_orders_path(facility)
    end
  end

  class ProblemReservationOrderDetails < MessageSummary
    private

    def allowed?
      facility && ability.can?(:show_problems, Reservation)
    end

    def get_count
      facility.problem_reservation_order_details.count
    end

    def l18n_key
      "message_summarizer.problem_reservation_order_details"
    end

    def path
      controller.show_problems_facility_reservations_path(facility)
    end
  end

  class TrainingRequests < MessageSummary
    private

    def allowed?
      facility && ability.can?(:manage, TrainingRequest)
    end

    def get_count
      facility.training_requests.count
    end

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
    @notifications ||= Notifications.new(@controller)
  end

  def order_details_in_dispute
    @order_details_in_dispute ||= OrderDetailsInDispute.new(@controller)
  end

  def problem_order_details
    @problem_order_details ||= ProblemOrderDetails.new(@controller)
  end

  def problem_reservation_order_details
    @problem_reservation_order_details ||= ProblemReservationOrderDetails.new(@controller)
  end

  def training_requests
    @training_requests ||= TrainingRequests.new(@controller)
  end

  private

  def message_summaries
    [
      notifications,
      order_details_in_dispute,
      problem_order_details,
      problem_reservation_order_details,
      training_requests,
    ].select(&:any?)
  end
end
