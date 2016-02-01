# Contains overrides for building a `NufsAccount` from params.
# Dynamically called via the `AccountBuilder.for()` factory.
class NufsAccountBuilder < AccountBuilder

  protected

  # Override strong_params for `build` account.
  def account_params_for_build
    [
      { account_number_parts: NufsAccount.account_number_field_names },
      :account_number,
      :description,
    ]
  end

  # Hooks into superclass's `build` method.
  def after_build
    set_expires_at
  end

  # Sets `expires_at` via a factory.
  def set_expires_at
    account.set_expires_at!
  rescue AccountNumberFormatError => e
    account.expires_at = Time.current
  end

end
