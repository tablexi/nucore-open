class FacilityAccount < ActiveRecord::Base
  belongs_to :facility

  validates_format_of       :account_number, :with => NucsValidator::NUCS_PATTERN, :message => "must be in the format 123-1234567-12345678-12-1234-1234; project, activity, program, and chart field 1 are optional"
  validates_numericality_of :revenue_account, :only_integer => true, :greater_than_or_equal_to => 10000, :less_than_or_equal_to => 99999
  validates_uniqueness_of   :account_number, :scope => [:revenue_account, :facility_id]

  scope :active,   :conditions => { :is_active => true }
  scope :inactive, :conditions => { :is_active => false }

  validate :validate_chartstring

  def to_s
    "#{account_number} (#{revenue_account})"
  end

  def fund
    split_account_number[1]
  end

  def dept
    split_account_number[2]
  end

  def project
    split_account_number[3]
  end

  def activity
    split_account_number[4]
  end

  def program
    split_account_number[5]
  end

  def validate_chartstring
    return if Rails.env.test?

    begin
      NucsValidator.new(account_number, revenue_account).account_is_open!
    rescue NucsErrors::NucsError => e
      errors.add(:account_number, e.message)
    end
  end

  protected

  def split_account_number
    return [] unless account_number
    account_number.match(NucsValidator::NUCS_PATTERN) || []
  end
end
