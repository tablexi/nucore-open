class CreditCardAccount < Account
  attr_readonly :account_number
  before_validation_on_create :validate_credit_card_number
  before_create :mask_credit_card_number
  
  validates_presence_of :account_number, :name_on_card
  validates_numericality_of :expiration_month, :only_integer => true, :greater_than => 0, :less_than => 13
  validate :expiration_year_in_future

  def expiration_year_in_future
    if expiration_year.nil? || expiration_year < Time.zone.now.year || expiration_year > Time.zone.now.year + 20
      self.errors.add(:expiration_year, "must be between #{Time.zone.now.year} and #{Time.zone.now.year + 20}")
    end
  end

  def validate_credit_card_number
    # validate account number format
    return false if self.account_number.blank?
    
    if !self.account_number.creditcard?
      self.errors.add(:account_number, "is an invalid credit card number")
      return false
    end

    true
  end

  protected

  def mask_credit_card_number
    # mask the card number
    if self.account_number.creditcard_type == 'american_express'
      self.account_number = "xxxx-xxxxxx-x#{self.account_number.slice(-4,4)}"
    else
      self.account_number = "xxxx-xxxx-xxxx-#{self.account_number.slice(-4,4)}"
    end
  end

end
