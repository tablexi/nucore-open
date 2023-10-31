# frozen_string_literal: true

class DurationRate < ApplicationRecord

  belongs_to :price_group
  belongs_to :rate_start

  validate :rate_or_subsidy
  validates :rate, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :subsidy, numericality: { greater_than: 0, allow_blank: true }

  # TODO: Validate both rate and subsidy are lesser than or equal to base rate
  # Question: Are all base rate price groups global? Is that the way of knowing whether a price group is the Base one?

  private
  def rate_or_subsidy
    if rate.blank? && subsidy.blank?
      errors.add(:base, "Either Rate or Adjustment must be provided")
    end
  end
end
