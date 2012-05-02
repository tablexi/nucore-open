class FacilityAccount < ActiveRecord::Base
  belongs_to :facility

  validates_format_of       :account_number, :with => ValidatorFactory.pattern, :message => I18n.t('activerecord.errors.messages.bad_payment_source_format', :pattern_format => ValidatorFactory.pattern_format)
  validates_numericality_of :revenue_account, :only_integer => true, :greater_than_or_equal_to => 10000, :less_than_or_equal_to => 99999
  validates_uniqueness_of   :account_number, :scope => [:revenue_account, :facility_id]

  scope :active,   :conditions => { :is_active => true }
  scope :inactive, :conditions => { :is_active => false }

  validate :validate_chartstring

  def to_s
    "#{account_number} (#{revenue_account})"
  end


  def method_missing(method_sym, *arguments, &block)
    return super unless account_number
    ValidatorFactory.instance(account_number).send(method_sym, *arguments)
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
    return if Rails.env.test?

    begin
      ValidatorFactory.instance(account_number, revenue_account).account_is_open!
    rescue ValidatorError => e
      errors.add(:account_number, e.message)
    end
  end

end
