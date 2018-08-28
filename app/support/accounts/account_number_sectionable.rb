# frozen_string_literal: true

module Accounts::AccountNumberSectionable

  extend ActiveSupport::Concern

  module ClassMethods

    def account_number_field_names
      new.account_number_fields.keys
    end

  end

  def account_number_fields
    { account_number: { required: true } }
  end

  def account_number_to_s
    account_number
  end

  def account_number_to_storage_format
    account_number_parts.account_number.to_s
  end

  def account_number_parts
    @account_number_parts
  end

  def account_number_parts=(fields)
    @account_number_parts = OpenStruct.new(fields)
    self.account_number = account_number_to_storage_format
  end

end
