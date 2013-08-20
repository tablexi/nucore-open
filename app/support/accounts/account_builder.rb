class Accounts::AccountBuilder
  def initialize(facility, user, params)
    @facility = facility
    @type = params[:class_type]
    @user = user
    @params = params
    @class_params = params[class_param_key]
  end

  def account
    @account ||= build_account
  end

private

  def class_param_key
    valid_keys = ['account'] + AccountManager.new.valid_account_types.map { |t| t.name.underscore }
    @params.keys.find { |key| valid_keys.include? key }
  end

  def build_account
    acct_class = AccountManager.account_type_by_string(@type)
    update_affiliate_params if acct_class.included_modules.include?(AffiliateAccount)
    @account = acct_class.new(new_class_params)
    @account.facility_id = @facility.id if @account.class.limited_to_single_facility?
    @account
  end

  def update_affiliate_params
    @class_params[:affiliate_other] = nil if @class_params[:affiliate_id] != Affiliate.OTHER.id.to_s
  end

  def new_class_params
    @class_params.merge(
      :created_by => @user.id,
      :account_users_attributes => [{
        :user_id => @params[:owner_user_id],
        :user_role => 'Owner',
        :created_by => @user.id
      }]
    )
  end
end