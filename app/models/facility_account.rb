# frozen_string_literal: true

class FacilityAccount < ApplicationRecord

  include Accounts::AccountNumberSectionable

  belongs_to :facility

  validates :revenue_account, numericality: { only_integer: true }
  validates :account_number, presence: true, uniqueness: { scope: [:revenue_account, :facility_id], case_sensitive: false }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  alias_attribute :active, :is_active

  def to_s
    "#{account_number} (#{revenue_account})"
  end

  def method_missing(method_sym, *arguments, &block)
    super # we must call super! Not doing so makes ruby 1.9.2 die a hard death
  rescue NoMethodError => e
    raise e unless account_number
    validator = ValidatorFactory.instance(account_number)
    raise e unless validator.components.key?(method_sym)
    validator.send(method_sym, *arguments)
  end

  def respond_to?(method_sym, include_private = false)
    return true if super

    begin
      return account_number && ValidatorFactory.instance(account_number).respond_to?(method_sym)
    rescue
      return false
    end
  end

end
