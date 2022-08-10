module AccountFieldsHelper

  # This allows you to set a default value for a section of the account
  # number, e.g. the `account_code` section of the account number can have a
  # default.
  #
  # Outputs an account section's field value from params, or the account
  # section's field default value, if it has one.
  def account_field_value(params, account_class, section, default = nil)
    key = account_class.name.underscore.split("/").last.to_sym
    value = params.dig(key, :account_number_parts, section)

    value || default
  end

end
