module AccountSuspendActions
  # GET /facilities/:facility_id/accounts/:account_id/suspend
  def suspend
    begin
      @account.suspend!
      flash[:notice] = I18n.t 'controllers.facility_accounts.suspend.success'
    rescue => e
      flash[:notice] = e.message || I18n.t('controllers.facility_accounts.suspend.failure')
    end

    redirect_to open_or_facility_path('account', @account)
  end

  # GET /facilities/:facility_id/accounts/:account_id/unsuspend
  def unsuspend
    begin
      @account.unsuspend!
      flash[:notice] = I18n.t 'controllers.facility_accounts.unsuspend.success'
    rescue => e
      flash[:notice] = e.message || I18n.t('controllers.facility_accounts.unsuspend.failure')
    end

    redirect_to open_or_facility_path('account', @account)
  end
end
