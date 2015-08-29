class MessageSummarizer
  include Enumerable

  delegate :each, to: :message_summaries

  def initialize(controller)
    @controller = controller
  end

  def message_count
    message_summaries.sum(&:count)
  end

  def messages?
    message_summaries.any?
  end

  private

  def notifications
    @notifications ||= NotificationsSummary.new(@controller)
  end

  def order_details_in_dispute
    @order_details_in_dispute ||= OrderDetailsInDisputeSummary.new(@controller)
  end

  def problem_order_details
    @problem_order_details ||= ProblemOrderDetailsSummary.new(@controller)
  end

  def problem_reservation_order_details
    @problem_reservation_order_details ||=
      ProblemReservationOrderDetailsSummary.new(@controller)
  end

  def training_requests
    @training_requests ||= TrainingRequestsSummary.new(@controller)
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
end
