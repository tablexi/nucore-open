module Accounts::AccountNumberSectionable
  def account_number_fields
    { :account_number => { :required => true } }
  end

  def account_number_to_s
    self.account_number
  end

  def account_number_to_storage_format
    "#{account_number_parts.account_number}"
  end

  def account_number_parts
    @account_number_parts
  end

  def account_number_parts=(fields)
    @account_number_parts = OpenStruct.new(fields)
    self.account_number = account_number_to_storage_format
  end
end
