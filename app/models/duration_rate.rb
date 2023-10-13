# frozen_string_literal: true

class DurationRate < ApplicationRecord

  belongs_to :instrument, foreign_key: :product_id

end
