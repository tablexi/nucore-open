#
# Call this method in a before(:all) block at the top of your +describe+
def create_users
  @users=[]

  [ 'admin', 'director', 'staff', 'guest', 'owner', 'purchaser' ].each do |name|
    user=Factory.create(:user, :username => name)
    instance_variable_set("@#{name}".to_sym, user)
    @users << user
  end

  UserRole.grant(@admin, UserRole::ADMINISTRATOR)
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
  method(@method).call(@action, params)
end


#
# The helpers below are useful for testing the authentication
# and authorization frameworks. They rely on the existence
# of instance variable @authable, which is the resource passed
# to +Ability#initialize+. They make requests for you using
# #do_request, so just set instance variables for it and you're
# good to go
#

#
# Asserts that the request is redirected to the login page 
def it_should_require_login
  it 'should require login' do
    do_request
    should redirect_to(new_user_session_url(:unauthenticated => true))
  end
end


#
# Asserts that the user is denied authorization
# [_user_sym_]
#   The +Symbol+ic username of the #create_users user to test
# [_spec_desc_]
#   If present is passed to the spec as its description
def it_should_deny(user_sym, spec_desc='')
  it "should deny #{user_sym.to_s} " + spec_desc do
    maybe_grant_always_sign_in(user_sym)
    do_request
    should render_template('403.html.erb')
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
  it "should allow #{user_sym.to_s} " + spec_desc do
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
    it "should allow #{user_sym.to_s} " + spec_desc do
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
  facility_managers + [ :staff ]
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

  it_should_allow_all(facility_managers, spec_desc) do |user|
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
  authable=@authable unless authable

  case user.username
    when 'director'
      UserRole.grant(user, UserRole::FACILITY_DIRECTOR, authable)
      user.reload.should be_facility_director_of(authable)
    when 'staff'
      UserRole.grant(user, UserRole::FACILITY_STAFF, authable)
      user.reload.should be_facility_staff_of(authable)
    when 'owner'
      AccountUser.grant(user, AccountUser::ACCOUNT_OWNER, authable, @admin)
      user.reload.should be_owner_of(authable)
    when 'purchaser'
      AccountUser.grant(user, AccountUser::ACCOUNT_PURCHASER, authable, @admin)
      user.reload.should be_purchaser_of(authable)
  end
end


def maybe_grant_always_sign_in(user_sym)
  user=instance_variable_get("@#{user_sym.to_s}")
  grant_role(user) unless user == @guest or user == @admin
  sign_in user
  return user
end