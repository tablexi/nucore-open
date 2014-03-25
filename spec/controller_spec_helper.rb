shared_context "feature enabled" do |feature|
  before(:all) do
    SettingsHelper.enable_feature(feature)
    Nucore::Application.reload_routes!
  end

  after(:all) do
    Settings.reload!
    Nucore::Application.reload_routes!
  end
end

shared_context "feature disabled" do |feature|
  before(:all) do
    SettingsHelper.enable_feature(feature, false)
    Nucore::Application.reload_routes!
  end

  after(:all) do
    Settings.reload!
    Nucore::Application.reload_routes!
  end
end


#
# Call this method in a before(:all) block at the top of your +describe+
def create_users
  @users=[]

  [ 'admin', 'director', 'staff', 'guest', 'owner', 'purchaser', 'business_admin', 'senior_staff', 'billing_admin' ].each do |name|
    user=FactoryGirl.create(:user, :username => name)
    instance_variable_set("@#{name}".to_sym, user)
    @users << user
  end

  UserRole.grant(@admin, UserRole::ADMINISTRATOR)
  UserRole.grant(@billing_admin, UserRole::BILLING_ADMINISTRATOR)
end


#
# This nifty method allows you to keep DRY the requests of a context.
# It relies on the following instance variables:
#
# * @method -- a +Symbol+ of a HTTP method (:get, :post, etc.)
# * @action -- the +Symbol+ of a controller action
# * @params -- a +Hash+ of requests parameters
#
# Once these instance variables are set you can call #do_request
# and the request described by the variables will be made.
# [_params_]
#   Overrides the @params variable
def do_request(params=nil)
  params=@params unless params
  if @method == :xhr
    xhr :get, @action, params
  else
    method(@method).call(@action, params)
  end
end

# This does what Users#switch_to does and sets the acting user.
# This will make ApplicationController#acting_as? return true and
# ApplicationController#acting_user return a user
def switch_to(user)
  session[:acting_user_id] = user.id
end


#
# The helpers below are useful for testing the authentication
# and authorization frameworks. They rely on the existence
# of let(:authable), which is the resource passed to +Ability#initialize+.
# They make requests for you using #do_request, so just set instance
# variables for it and you're good to go
#
# Note: instance variable @authable, also works for setup, but is deprecated
#

#
# Asserts that the request is redirected to the login page
def it_should_require_login
  it 'should require login', :auth => true do
    do_request
    should redirect_to(new_user_session_url)
  end
end


#
# Asserts that the user is denied authorization
# [_user_sym_]
#   The +Symbol+ic username of the #create_users user to test
# [_spec_desc_]
#   If present is passed to the spec as its description
def it_should_deny(user_sym, spec_desc='')
  it "should deny #{user_sym.to_s} " + spec_desc, :auth => true do
    maybe_grant_always_sign_in(user_sym)
    do_request
    should render_template('403')
  end
end


#
# Grants a user a role based on their username and signs them in
# allowance of authorization is tested in the given block
# [_user_sym_]
#   The +Symbol+ic username of the #create_users user to test
# [_spec_desc_]
#   If present is passed to the spec as its description
# [_eval_]
#   block of tests to be evaluated after roles are
#   granted and the user is signed in
def it_should_allow(user_sym, spec_desc='', &eval)
  it "should allow #{user_sym.to_s} " + spec_desc, :auth => true do
    maybe_grant_always_sign_in(user_sym)
    do_request
    instance_eval &eval
  end
end

#
# The *_all helpers are useful for testing multiple roles in one shot.
# They generate a new spec for each role and behave just like their
# single counterparts above
# [_user_syms_]
#   An Array of the +Symbol+ic usernames of #create_users users to test
#

def it_should_deny_all(user_syms, spec_desc='')
  user_syms.each { |user_sym| it_should_deny user_sym, spec_desc }
end


def it_should_allow_all(user_syms, spec_desc='', &eval)
  user_syms.each do |user_sym|
    it "should allow #{user_sym.to_s} " + spec_desc, :auth => true do
      user=maybe_grant_always_sign_in(user_sym)
      do_request
      instance_exec(user, &eval)
    end
  end
end


#
# Convenient params for *_all helpers
#

def facility_managers
  [ :admin, :director ]
end


def facility_operators
  facility_managers + [ :staff, :senior_staff ]
end


def facility_users
  facility_operators + [ :guest ]
end


#
# Bundles the common test suite of ensuring an action requires
# login, denies facility staff, and allows facility managers.
# [_response_]
#   The expected HTTP status on a successful auth. Can be
#   anything expected by +Shoulda::Matchers::ActionController#respond_with+.
#   Defaults to :success
# [_spec_desc_]
#   If present is passed to the spec as its description
# [_eval_]
#   A block holding successful auth tests. If given will be passed the
#   user whose auth is currently being tested. Not required.
def it_should_allow_managers_only(response=:success, spec_desc='', &eval)
  it_should_require_login

  it_should_deny(:guest, spec_desc)

  it_should_deny(:staff, spec_desc)

  it_should_deny(:senior_staff)

  it_should_allow_all(facility_managers, spec_desc) do |user|
    should respond_with response
    instance_exec(user, &eval) if eval
  end

  it 'should test more than auth' unless eval
end

def it_should_allow_managers_and_senior_staff_only(response=:success, spec_desc='', &eval)
  it_should_require_login

  it_should_deny(:guest, spec_desc)

  it_should_deny(:staff, spec_desc)

  it_should_allow_all(facility_managers + [:senior_staff], spec_desc) do |user|
    should respond_with response
    instance_exec(user, &eval) if eval
  end

  it 'should test more than auth' unless eval
end


#
# Similar to #it_should_allow_managers_only, but for operators
def it_should_allow_operators_only(response=:success, spec_desc='', &eval)
  it_should_require_login

  it_should_deny(:guest, spec_desc)

  it_should_allow_all(facility_operators, spec_desc) do |user|
    should respond_with response
    instance_exec(user, &eval) if eval
  end

  it 'should test more than auth' unless eval
end


#
# Similar to #it_should_allow_managers_only, but tests admin access
def it_should_allow_admin_only(response=:success, spec_desc='', &eval)
  it_should_require_login

  it_should_deny(:guest, spec_desc)

  it_should_deny(:director, spec_desc)

  it_should_deny(:staff, spec_desc)

  it_should_allow(:admin, spec_desc) do
    should respond_with response
    instance_eval &eval if eval
  end

  it 'should test more than auth' unless eval
end


#
# Helpers for the above API. Stand-alone use is discouraged.
#

def grant_role(user, authable=nil)
  if authable.nil?
    authable = @authable
    authable = send(:authable) if authable.nil? && respond_to?(:authable)
  end

  case user.username
    when 'director'
      UserRole.grant(user, UserRole::FACILITY_DIRECTOR, authable)
      user.reload.should be_facility_director_of(authable)
    when 'staff'
      UserRole.grant(user, UserRole::FACILITY_STAFF, authable)
      user.reload.should be_facility_staff_of(authable)
    when 'owner'
      # Creating a NufsAccount requires an owner to be present, and some pre-Rails3 tests try to add the same user
      # to the same account with the same role of owner. That's a uniqueness error on AccountUser. Avoid it.
      existing=AccountUser.find_by_user_id_and_account_id_and_user_role(user.id, authable.id, AccountUser::ACCOUNT_OWNER)
      AccountUser.grant(user, AccountUser::ACCOUNT_OWNER, authable, @admin) unless existing
      user.reload.should be_owner_of(authable)
    when 'purchaser'
      AccountUser.grant(user, AccountUser::ACCOUNT_PURCHASER, authable, @admin)
      user.reload.should be_purchaser_of(authable)
    when 'business_admin'
      AccountUser.grant(user, AccountUser::ACCOUNT_ADMINISTRATOR, authable, @admin)
      user.reload.should be_business_administrator_of(authable)
    when 'senior_staff'
      UserRole.grant(user, UserRole::FACILITY_SENIOR_STAFF, authable)
      user.reload.should be_facility_senior_staff_of(authable)
  end
end

def grant_and_sign_in(user)
  grant_role(user) unless user == @guest || user == @admin
  sign_in user
  return user
end

def maybe_grant_always_sign_in(user_sym)
  user=instance_variable_get("@#{user_sym.to_s}")
  grant_and_sign_in(user)
end

def split_date_to_params(key, date)
  {
    :"#{key}_date" => format_usa_date(date),
    :"#{key}_hour" => date.strftime("%I"),
    :"#{key}_min" => date.min.to_s,
    :"#{key}_meridian" => date.strftime('%p')
  }
end


# Takes a parameter set and replaces _start_at and _end_at DateTime parameters split up into their other fields
# like reserve_start_date, reserve_start_hour, and duration_unit
# Alters the params hash
def parametrize_dates(params, key)
  start_time = params[:"#{key}_start_at"]
  end_time = params[:"#{key}_end_at"]

  params.merge!(split_date_to_params("#{key}_start", start_time))
  params.merge!(:duration_value => ((end_time - start_time) / 60).ceil.to_s, :duration_unit => 'minutes')

  params.delete :"#{key}_start_at"
  params.delete :"#{key}_end_at"

  params
end
