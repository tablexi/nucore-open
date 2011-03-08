class PriceGroupMember < ActiveRecord::Base
  belongs_to :price_group

  validates_presence_of :price_group_id
end
