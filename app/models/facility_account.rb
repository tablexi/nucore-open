class FacilityAccount < ActiveRecord::Base

  include Accounts::AccountNumberSectionable

  belongs_to :facility

  validates :revenue_account, numericality: { only_integer: true }
  validates_uniqueness_of :account_number, scope: [:revenue_account, :facility_id]
  validate :validate_chartstring

  scope :active,   conditions: { is_active: true }
  scope :inactive, conditions: { is_active: false }

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

  def validate_chartstring
    ValidatorFactory.instance(account_number, revenue_account).account_is_open!
  rescue AccountNumberFormatError => e
    e.apply_to_model(self)
  rescue ValidatorError => e
    errors.add(:account_number, e.message)
  end

end
