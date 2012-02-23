class NufsAccount < Account
  include Validations
  
  validates_format_of     :account_number, :with => ValidatorFactory.pattern, :message => I18n.t('activerecord.errors.messages.bad_payment_source_format', :pattern_format => ValidatorFactory.pattern_format)
  validates_uniqueness_of :account_number, :message => "already exists"

  validate :check_chartstring

  def check_chartstring
    validate_chartstring
  end

  def set_expires_at!
    self.expires_at = ValidatorFactory.instance(account_number).latest_expiration
  end
  
  def account_open? (account_num)
    begin
      ValidatorFactory.instance(account_number, account_num).account_is_open!
    rescue ValidatorError
      return false
    end

    return true
  end
end
