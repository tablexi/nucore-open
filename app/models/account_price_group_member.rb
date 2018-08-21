# frozen_string_literal: true

class AccountPriceGroupMember < PriceGroupMember

  belongs_to :account

  validates_presence_of :account_id
  validates_uniqueness_of :account_id, scope: [:price_group_id]

end
