class MessageSummarizer

  include Enumerable

  delegate :each, to: :visible_summaries

  def initialize(controller)
    @controller = controller
  end

  def messages?
    message_count > 0
  end

  def tab_label
    I18n.t("message_summarizer.heading", count: message_count)
  end

  def visible_tab?
    visible_summaries.any?
  end

  def visible_summaries
    summaries.select(&:visible?)
  end

  def summaries
    [
      notifications,
      order_details_in_dispute,
      problem_order_details,
      problem_reservation_order_details,
      training_requests,
    ]
  end

  private

  def message_count
    @message_count ||= visible_summaries.sum(&:count)
  end

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

end
