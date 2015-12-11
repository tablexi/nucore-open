# Contains overrides for building a `NufsAccount` from params.
# Dynamically called via the `AccountBuilder.for()` factory.
class NufsAccountBuilder < AccountBuilder

  protected

  # Hooks into superclass's `build` method.
  def after_build
    set_expires_at
  end

  # Sets `expires_at` via a factory.
  def set_expires_at
    account.set_expires_at!
    account
  end

end
