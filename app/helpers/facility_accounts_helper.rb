module FacilityAccountsHelper

  def needs_reconcile_warning?(order_detail)
    !order_detail.reconciled? && order_detail.fulfilled_at && (Time.zone.now.to_date - order_detail.fulfilled_at.to_date).to_i >= 60
  end

end