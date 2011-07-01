require 'spec_helper'; require 'controller_spec_helper'

describe AccountsController do
  render_views
  
  it "should route" do
    { :get => "/accounts" }.should route_to(:controller => 'accounts', :action => 'index')
    { :get => "/accounts/1" }.should route_to(:controller => 'accounts', :action => 'show', :id => '1')
    { :get => "/accounts/1/user_search" }.should route_to(:controller => 'accounts', :action => 'user_search', :id => '1')
  end

  before(:all) { create_users }

  before(:each) do
    @authable = create_nufs_account_with_owner
  end


  context "index" do

    before(:each) do
      @method=:get
      @action=:index
    end

    it_should_require_login

    it "should list accounts, with edit account links for account owner" do
      create_nufs_account_with_owner
      maybe_grant_always_sign_in(:owner)
      do_request
      # should find 2 account users, with user roles 'Owner'
      assigns[:account_users].collect(&:user_id).should == [ @owner.id, @owner.id ]
      assigns[:account_users].collect(&:user_role).should == [ 'Owner', 'Owner' ]
      # should show 2 accounts, with 'edit account' links
      response.should render_template('accounts/index')
    end

    it_should_allow :purchaser do
      # should find 1 account user, with user roles as 'Purchaser'
      assigns[:account_users].collect(&:user_id).should == [@purchaser.id]
      assigns[:account_users].collect(&:user_role).should == ['Purchaser']
      # should show 1 account, with no 'edit account' links
      response.should render_template('accounts/index')
    end
  end


  context "show" do

    before :each do
      @method=:get
      @action=:show
      @params={ :id => @authable.id }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      assigns(:account).should == @authable
      response.should render_template('accounts/show')
    end
  end


  context 'user_search' do

    before :each do
      @method=:get
      @action=:user_search
      @params={ :id => @authable.id }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      assigns(:account).should == @authable
      response.should render_template('account_users/user_search')
    end

  end


  context "POST /accounts/create" do
    it "should 403 unless class_type is NufsAccount, CreditCardAccount, or PurchaseOrderAccount"
  end

end

