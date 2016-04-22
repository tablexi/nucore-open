class AvailableAccountsFinder

  def initialize(user, facility, current: nil)
    @user = user
    @facility = facility
    @current_account = current
  end

  def accounts
    accounts = @user.accounts.for_facility(@facility).active
    if @current_account && !accounts.include?(@current_account)
      accounts += [@current_account]
    end
    accounts
  end
  alias to_a accounts

end
