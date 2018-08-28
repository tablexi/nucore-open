# frozen_string_literal: true

class PriceGroupMember < ApplicationRecord

  belongs_to :price_group

  validates_presence_of :price_group_id

end
