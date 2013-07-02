module FacilityOrdersHelper
  def order_detail_notices(order_detail)
    notices = []

    notices << 'in-review' if order_detail.in_review?
    notices << 'reviewed' if order_detail.reviewed?
    notices << 'in-dispute' if order_detail.in_dispute?
    notices << 'can-reconcile' if order_detail.can_reconcile?

    warnings = []
    warnings << 'missing-actuals' if order_detail.reservation.try(:requires_but_missing_actuals?)
    warnings << 'missing-price-policy' if order_detail.missing_price_policy?

    { :warnings => warnings, :notices => notices }
  end

  def order_detail_badges(order_detail)
    badges = order_detail_notices(order_detail)
    output = []
    badges[:warnings].each do |warning|
      output << content_tag(:span, warning, :class => ['label', 'label-important'])
    end

    badges[:notices].each do |notice|
      output << content_tag(:span, notice, :class => ['label', 'label-info'])
    end
    output.join(' ').html_safe
  end


end
