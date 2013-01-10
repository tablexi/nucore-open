require 'spec_helper'
require 'controller_spec_helper'

describe FacilityAccountsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @facility_account=FactoryGirl.create(:facility_account, :facility => @authable)
    @item=FactoryGirl.create(:item, :facility_account => @facility_account, :facility => @authable)
    @account=create_nufs_account_with_owner
    grant_role(@purchaser, @account)
    grant_role(@owner, @account)
    @order=FactoryGirl.create(:order, :user => @purchaser, :created_by => @purchaser.id, :facility => @authable)
    @order_detail=FactoryGirl.create(:order_detail, :product => @item, :order => @order, :account => @account)
  end

  context 'index' do

    before(:each) do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      should assign_to(:accounts).with_kind_of(ActiveRecord::Relation)
      assigns(:accounts).size.should == 1
      assigns(:accounts).first.should == @account
      should render_template('index')
    end

  end


  context 'show' do

    before(:each) do
      @method=:get
      @action=:show
      @params={ :facility_id => @authable.url_name, :id => @account.id }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should render_template('show')
    end

  end


  context 'edit accounts', :if => SettingsHelper.feature_on?(:edit_accounts) do
    context 'new' do

      before(:each) do
        @method=:get
        @action=:new
        @params={ :facility_id => @authable.url_name, :owner_user_id => @owner.id }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        assigns(:owner_user).should == @owner
        assigns(:account).should be_new_record
        assigns(:account).expires_at.should_not be_nil
        should render_template('new')
      end

    end


    context 'edit' do

      before(:each) do
        @method=:get
        @action=:edit
        @params={ :facility_id => @authable.url_name, :id => @account.id }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        assigns(:account).should == @account
        should render_template('edit')
      end

    end


    context 'update' do

      before(:each) do
        @method=:put
        @action=:update
        @params={
          :facility_id => @authable.url_name,
          :id => @account.id,
          :account => FactoryGirl.attributes_for(:nufs_account)
        }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        assigns(:account).should == @account
        assigns(:account).affiliate.should be_nil
        assigns(:account).affiliate_other.should be_nil
        should set_the_flash
        assert_redirected_to facility_account_url
      end

    end


    context 'create' do

      before :each do
        @method=:post
        @action=:create
        @acct_attrs=FactoryGirl.attributes_for(:nufs_account)
        @params={
          :id => @account.id,
          :facility_id => @authable.url_name,
          :owner_user_id => @owner.id,
          :account => @acct_attrs,
          :class_type => 'NufsAccount'
        }
        @controller.stubs(:current_facility).returns(@authable)
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do |user|
        should assign_to(:account).with_kind_of(NufsAccount)
        assigns(:account).account_number.should == @acct_attrs[:account_number]
        assigns(:account).created_by.should == user.id
        assigns(:account).account_users.size.should == 1
        assigns(:account).account_users[0] == @owner
        assigns(:account).affiliate.should be_nil
        assigns(:account).affiliate_other.should be_nil
        should set_the_flash
        assert_redirected_to user_accounts_url(@authable, assigns(:account).owner_user)
      end

    end


    context 'new_account_user_search' do

      before :each do
        @method=:get
        @action=:new_account_user_search
        @params={ :facility_id => @authable.url_name }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        should render_template 'new_account_user_search'
      end

    end


    context 'user_search' do

      before :each do
        @method=:get
        @action=:user_search
        @params={ :facility_id => @authable.url_name }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        should render_template 'user_search'
      end

    end
  end

  
  context 'accounts_receivable' do

    before :each do
      @method=:get
      @action=:accounts_receivable
      @params={:facility_id => @authable.url_name}
    end

    it_should_allow_managers_only
    it_should_deny_all [:staff, :senior_staff]
  end


  context 'search' do

    before :each do
      @method=:get
      @action=:search
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      should render_template 'search'
    end

  end


  #TODO: ping Chris / Matt for functions / factories
  #      to create other accounts w/ custom numbers
  #      and non-nufs type
  context 'search_results' do

    before :each do
      @method=:get
      @action=:search_results
      @params={ :facility_id => @authable.url_name, :search_term => @owner.username }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      assigns(:accounts).size.should == 1
      should render_template('search_results')
    end


    context 'POST' do

      before(:each) { @method=:post }

      it_should_allow :director do
        assigns(:accounts).size.should == 1
        should render_template('search_results')
      end

    end

  end


  context 'user_accounts' do

    before :each do
      @method=:get
      @action=:user_accounts
      @params={ :facility_id => @authable.url_name, :user_id => @guest.id }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      assigns(:user).should == @guest
      should render_template('user_accounts')
    end

  end


  context 'members' do

    before :each do
      @method=:get
      @action=:members
      @params={ :facility_id => @authable.url_name, :account_id => @account.id }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should render_template('members')
    end

  end


  context 'show_statement', :if => AccountManager.using_statements? do

    before :each do
      @method=:get
      @action=:show_statement

      2.times do
        @statement=FactoryGirl.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :account => @account)
        sleep 1 # need different timestamp on statement
      end

      @params={ :facility_id => @authable.url_name, :account_id => @account.id, :statement_id => 'recent' }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      assigns(:facility).should == @authable
      should assign_to(:order_details).with_kind_of Array
      assigns(:order_details).each{|od| od.order.facility.should == @authable }
      should render_template 'show_statement'
    end

    it 'should show statements list' do
      @params[:statement_id]='list'
      maybe_grant_always_sign_in :director
      do_request
      assigns(:account).should == @account
      assigns(:facility).should == @authable
      should assign_to(:statements).with_kind_of Array
      should render_template 'show_statement_list'
    end


    it 'should show statement PDF' do
      @params[:statement_id]=@statement.id
      @params[:format]='pdf'
      maybe_grant_always_sign_in :director
      do_request
      assigns(:account).should == @account
      assigns(:facility).should == @authable
      assigns(:statement).should == @statement
      response.content_type.should == "application/pdf"
      response.body.should =~ /%PDF-1.3/
      should render_template 'statements/show'
    end

  end


  context 'suspension', :if => SettingsHelper.feature_on?(:suspend_accounts) do
    context 'suspend' do

      before :each do
        @method=:get
        @action=:suspend
        @params={ :facility_id => @authable.url_name, :account_id => @account.id }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        assigns(:account).should == @account
        should set_the_flash
        assert_redirected_to facility_account_path(@authable, @account)
      end

    end


    context 'unsuspend' do

      before :each do
        @method=:get
        @action=:unsuspend
        @params={ :facility_id => @authable.url_name, :account_id => @account.id }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        assigns(:account).should == @account
        should set_the_flash
        assert_redirected_to facility_account_path(@authable, @account)
      end

    end
  end

end
