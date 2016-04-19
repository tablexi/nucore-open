class AvailableAccountsFinder

  def initialize(user, facility, current: nil)
    @user = user
    @facility = facility
    @current_account = current
  end

  def accounts
    accounts = @user.accounts.for_facility(@facility).active
    accounts += [@current_account] if @current_account
    accounts
  end
  alias to_a accounts

end
