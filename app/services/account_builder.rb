# Builds an Account object given params.
# This class supports extensions from engines via the `build_subclass` method.
class AccountBuilder

  # The `do` method for this service object.
  # Extendable via the `build_subclass` method call.
  # Returns the built account object.
  def build(facility, current_user, owner_user, params)
    account_type = valid_account_type!(params[:account_type], facility)
    account = new_account(account_type, params)
    account = build_account_users(account, current_user, params)
    account = build_affiliate(account, params)
    account = build_created_by(account, current_user)
    account = build_facility(account, facility)
    account = build_subclass(account, params)
    binding.pry
    account
  end

  private

  # Dynamically calls a subclass method if one exists. Returns a modified
  # account object.
  def build_subclass(account, params)
    method = "build_#{Account.account_type_to_param(account.class.to_s)}"
    return account unless respond_to?(method, true)
    account = send(method, account, params)
  end

  # Build an owner account_user.
  # Returns the modified account object.
  def build_account_users(account, current_user, params)
    owner = User.find(params[:owner_user_id])
    account.account_users.build(
      user_id: owner.id,
      user_role: 'Owner',
      created_by: current_user.id,
    )
    account
  end

  # Set the affiliate for an account only if affiliates are supported for the
  # given account type.  Returns the modified account object.
  def build_affiliate(account, params)
    return account unless account.class.included_modules.include?(AffiliateAccount)
    key = Account.account_type_to_param(account.class.to_s)
    account.affiliate_other = nil if params[key][:affiliate_id] != Affiliate.OTHER.id.to_s
    account
  end

  # Set the created_by attribute for an account.
  # Returns the modified account object.
  def build_created_by(account, current_user)
    account.created_by = current_user.id
    account
  end

  # Set the faciltiy for an account.
  # Returns the modified account object.
  def build_facility(account, facility)
    account.facility_id = facility.id if facility.present?
    account
  end

  # Dynamically called by `build_subclass` if the account_type is NufsAccount.
  def build_nufs_account(account, params)
    account = build_nufs_account_expires_at(account, params)
    account
  end

  # TODO: figure out how to refactor existing expires_at code. See both
  # `configure_new_account` and `set_expires_at!`. Those methods should get
  # deprecated.
  def build_nufs_account_expires_at(account, params)
    account.set_expires_at!
    account
  end

  # Given an account type, create a new account and assign params.
  # This method was only created in case we ever need to override it.
  def new_account(account_type, params)
    key = Account.account_type_to_param(account_type)
    account_type.constantize.new(params[key])
  end

  # Returns a valid subclassed Account object; unless account_type is invalid,
  # then raises an AccountController::RoutingErro exception.
  def valid_account_type!(account_type, facility)
    account_types = Account.creatable_account_types_for_facility(facility).map(&:to_s)
    return account_type if account_types.include?(account_type)
    raise ActionController::RoutingError, "invalid account_type: #{account_type}"
  end

end
