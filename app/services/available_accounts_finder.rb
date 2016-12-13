class AvailableAccountsFinder

  def initialize(user, facility, current: nil, current_user: nil)
    @user = user
    @current_user = current_user
    @facility = facility
    @current_account = current
  end

  def accounts
    accounts = @user.accounts.for_facility(@facility).active
    accounts &= @current_user.accounts.for_facility(@facility).active if @current_user
    accounts += [@current_account] if @current_account && !accounts.include?(@current_account)
    accounts
  end
  alias to_a accounts

end
