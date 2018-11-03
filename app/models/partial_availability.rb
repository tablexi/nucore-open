# frozen_string_literal: true

class PartialAvailability < ApplicationRecord

  belongs_to :instrument

  validates :note, presence: true, length: { maximum: 256 }

end
