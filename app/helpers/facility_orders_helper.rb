module FacilityOrdersHelper
  def order_detail_notices(order_detail)
    notices = []
    notices << 'in-review' if order_detail.in_review?
    notices << 'reviewed' if order_detail.reviewed?
    notices << 'missing-actuals' if order_detail.reservation.try(:requires_but_missing_actuals?)
    notices << 'missing-price-policy' if order_detail.missing_price_policy?
    notices << 'problem-order' if order_detail.problem_order?
    notices << 'in-dispute' if order_detail.in_dispute?
    notices << 'can-reconcile' if order_detail.can_reconcile?
    notices
  end
end
