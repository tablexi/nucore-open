class NufsAccount < Account
  include Validations
  
  validates_format_of     :account_number, :with => NucsValidator::NUCS_PATTERN, :message => "must be in the format 123-1234567-12345678-12-1234-1234; project, activity, program, and chart field 1 are optional"
  validates_uniqueness_of :account_number, :message => "already exists"

  def validate
    validate_chartstring
  end

  def set_expires_at!
    self.expires_at = NucsValidator.new(account_number).latest_expiration
  end
  
  def account_open? (account_num)
    begin
      NucsValidator.new(account_number, account_num).account_is_open!
    rescue NucsError
      return false
    end

    return true
  end
end
