# frozen_string_literal: true

class PurchaseOrderAccount < Account

  include AffiliateAccount
  include ReconcilableAccount

  validates_presence_of :account_number

  def to_s(with_owner = false, flag_suspended = true)
    desc = super(with_owner, false)
    desc += " / #{facilities.first}" if per_facility?
    desc += " (#{display_status.upcase})" if flag_suspended && suspended?
    desc
  end

end
