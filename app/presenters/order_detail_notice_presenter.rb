class OrderDetailNoticePresenter < DelegateClass(OrderDetail)

  include ActionView::Helpers::OutputSafetyHelper

  def statuses
    [].tap do |statuses|
      statuses << Notice.new(:in_review) if in_review?
      statuses << Notice.new(:in_dispute) if in_dispute?
      statuses << Notice.new(:can_reconcile) if can_reconcile_journaled?
      statuses << Notice.new(:in_open_journal) if in_open_journal?
    end
  end

  def warnings
    [].tap do |warnings|
      warnings << Notice.new(problem_description_key, :warning) if problem?
    end
  end

  def notices
    statuses + warnings
  end

  def badges_to_html
    safe_join(notices.map(&:badge_to_html))
  end

  # Not meant to be used outside the presenter class
  class Notice

    include ActionView::Helpers::TagHelper

    def initialize(key, severity = :status)
      @key = key
      @severity = severity
    end

    def badge_text
      I18n.t("order_details.notices.#{@key}.badge")
    end

    def alert_text
      I18n.t("order_details.notices.#{@key}.alert")
    end

    def badge_to_html
      content_tag(:span, badge_text, class: ["label", label_class])
    end

    private

    def label_class
      {
        status: "label-info",
        warning: "label-important",
      }.fetch(@severity)
    end

  end

end
