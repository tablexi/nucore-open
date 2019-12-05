# frozen_string_literal: true

class UserPriceGroupMember < PriceGroupMember

  belongs_to :user, optional: true

  validates_presence_of :user_id
  validates_uniqueness_of :user_id, scope: [:price_group_id]

end
