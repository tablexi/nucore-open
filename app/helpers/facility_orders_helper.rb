module FacilityOrdersHelper
  def order_detail_notices(order_detail)
    notices = []

    notices << 'in_review' if order_detail.in_review?
    # notices << 'reviewed' if order_detail.reviewed?
    notices << 'in_dispute' if order_detail.in_dispute?
    notices << 'can_reconcile' if order_detail.can_reconcile?
    notices << 'in_open_journal' if order_detail.in_open_journal?

    warnings = []
    warnings << 'missing_actuals' if order_detail.complete? && order_detail.reservation.try(:requires_but_missing_actuals?)
    warnings << 'missing_price_policy' if order_detail.missing_price_policy? && !order_detail.reservation.try(:requires_but_missing_actuals?)

    { :warnings => warnings, :notices => notices }
  end

  def order_detail_badges(order_detail)
    notices = order_detail_notices(order_detail)

    output = build_badges(notices[:warnings], 'label-important')
    output += build_badges(notices[:notices], 'label-info')

    output.join(' ').html_safe
  end

  def banner_date_label(object, field)
    banner_label(object, field) do |value|
      value = human_datetime value
      value = yield(value) if value && block_given?
      value
    end
  end

  def banner_label(object, field)
    if value = object.send(:try, field)
      value = yield(value) if block_given?

      content_tag :dl, :class => 'span2' do
        content_tag(:dt, object.class.human_attribute_name(field)) +
        content_tag(:dd, value)
      end
    end
  end

  private

  def build_badges(notices, label_class)
    notices.map do |notice|
      content_tag(:span, t("order_details.notices.#{notice}.badge"), :class => ['label', label_class])
    end
  end
end
