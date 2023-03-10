# frozen_string_literal: true

class PriceGroupDiscount < ApplicationRecord
  belongs_to :price_group
  belongs_to :schedule_rule
end
