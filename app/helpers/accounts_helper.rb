module AccountsHelper
  def account_input(form)
    hint = t('facility_order_details.edit.label.account_owner_html', :owner => @order_detail.account.owner_user)
    form.input :account, :hint => hint do
      form.select :account_id, available_accounts_options, :include_blank => false, :disabled => edit_disabled?
    end
  end

  private

  def available_accounts_array
    @available_accounts.map do |account|
      [
        account.to_s,
        account.id,
        { 'data-account-owner' => account.owner_user_name },
      ]
    end
  end

  def available_accounts_options
    options_for_select(available_accounts_array, @order_detail.account_id)
  end
end
