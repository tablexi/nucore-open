class AvailableAccountsFinder

  def initialize(user, facility, current: nil, current_user: nil)
    @user = user
    @current_user = current_user
    @facility = facility
    @current_account = current
  end

  def accounts
    accounts = available_accounts
    if @current_account && !accounts.include?(@current_account)
      accounts += [@current_account]
    end
    accounts
  end
  alias to_a accounts

  private

  def available_accounts
    available_accounts = @user.accounts.for_facility(@facility).active
    available_accounts = available_accounts & @current_user.accounts.for_facility(@facility).active if @current_user
    available_accounts
  end

end
