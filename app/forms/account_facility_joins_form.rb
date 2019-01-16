# frozen_string_literal: true

class AccountFacilityJoinsForm

  include ActiveModel::Model

  attr_accessor :account

  validates :facility_ids, presence: true
  validates :account, presence: true

  def facility_ids
    @facility_ids || account.facilities.pluck(:id)
  end

  def facility_ids=(facility_ids)
    @facility_ids = Array(facility_ids).select(&:present?)
  end

  def save
    return unless valid?

    account.facilities = Facility.find(facility_ids)
    true
  end

end
