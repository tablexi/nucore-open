class AvailableAccountsFinder

  def initialize(user, facility)
    @user = user
    @facility = facility
  end

  def accounts
    @user.accounts.for_facility(@facility).active
  end
  alias_method :to_a, :accounts

end
