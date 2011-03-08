class CreditCardAccount < Account
  attr_readonly :account_number, :credit_card_number_encryted
  before_validation_on_create :validate_credit_card_number
  before_create :mask_credit_card_number
  
  validates_presence_of :account_number, :name_on_card
  validates_numericality_of :expiration_month, :only_integer => true, :greater_than => 0, :less_than => 13
  validate :expiration_year_in_future

  attr_accessor :credit_card_number

  def expiration_year_in_future
    if expiration_year.nil? || expiration_year < Time.zone.now.year || expiration_year > Time.zone.now.year + 20
      self.errors.add(:expiration_year, "must be between #{Time.zone.now.year} and #{Time.zone.now.year + 20}")
    end
  end

  # virtual attribute to handle encryption behind the scenes
  # The db attribute type is string so I need to convert it to Base64
  def credit_card_number=(ccn)
    if not ccn.blank?
      # remove all but digits when encrypting
      self.credit_card_number_encrypted = Encryption.encrypt(ccn.tr('^0-9',''))
    end
  end
 
  def credit_card_number
    if self.credit_card_number_encrypted.nil?
      nil
    else
      # format the CCN all pretty-like
      @number = Encryption.decrypt(self.credit_card_number_encrypted)
      if @number.creditcard_type == 'american_express'
        # format xxxx-xxxxxx-xxxxx
        [@number.slice(0,4), @number.slice(4,6), @number.slice(10,5)].join('-')
      else
        # format as xxxx-xxxx-xxxx-xxxx
        @number.gsub(/(\d{4})\B/, '\1-')
      end
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
    # set the credit card number
    self.credit_card_number = self.account_number

    # mask the card number
    if self.credit_card_number.creditcard_type == 'american_express'
      self.account_number = "xxxx-xxxxxx-x#{self.credit_card_number.slice(-4,4)}"
    else
      self.account_number = "xxxx-xxxx-xxxx-#{self.credit_card_number.slice(-4,4)}"
    end
  end

end
