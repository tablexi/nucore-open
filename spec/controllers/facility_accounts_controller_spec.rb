require "rails_helper"
require 'controller_spec_helper'

RSpec.describe FacilityAccountsController do
  let(:facility) { @authable }

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
      expect(assigns(:accounts)).to be_kind_of ActiveRecord::Relation
      expect(assigns(:accounts).size).to eq(1)
      expect(assigns(:accounts).first).to eq(@account)
      is_expected.to render_template('index')
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
      expect(assigns(:account)).to eq(@account)
      is_expected.to render_template('show')
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
        expect(assigns(:owner_user)).to eq(@owner)
        expect(assigns(:account)).to be_new_record
        is_expected.to render_template('new')
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
        expect(assigns(:account)).to eq(@account)
        is_expected.to render_template('edit')
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
        expect(assigns(:account)).to eq(@account)
        expect(assigns(:account).affiliate).to be_nil
        expect(assigns(:account).affiliate_other).to be_nil
        is_expected.to set_flash
        assert_redirected_to facility_account_url
      end

    end


    context 'create' do
      let(:owner_user) { assigns(:account).owner_user }

      before :each do
        @method=:post
        @action=:create
        @acct_attrs=FactoryGirl.attributes_for(:nufs_account)
        @params={
          :facility_id => @authable.url_name,
          :owner_user_id => @owner.id,
          :nufs_account => @acct_attrs,
          :account_type => 'NufsAccount'
        }
        allow(@controller).to receive(:current_facility).and_return(@authable)
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do |user|
        expect(assigns(:account)).to be_kind_of NufsAccount
        expect(assigns(:account).account_number).to eq(@acct_attrs[:account_number])
        expect(assigns(:account).created_by).to eq(user.id)
        expect(assigns(:account).account_users.size).to eq(1)
        assigns(:account).account_users[0] == @owner
        expect(assigns(:account).affiliate).to be_nil
        expect(assigns(:account).affiliate_other).to be_nil
        is_expected.to set_flash
        expect(response).to redirect_to(facility_user_accounts_path(facility, owner_user))
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
        is_expected.to render_template 'new_account_user_search'
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
        is_expected.to render_template 'user_search'
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
      is_expected.to render_template 'search'
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
      expect(assigns(:accounts).size).to eq(1)
      is_expected.to render_template('search_results')
    end


    context 'POST' do

      before(:each) { @method=:post }

      it_should_allow :director do
        expect(assigns(:accounts).size).to eq(1)
        is_expected.to render_template('search_results')
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
      expect(assigns(:user)).to eq(@guest)
      is_expected.to render_template('user_accounts')
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
      expect(assigns(:account)).to eq(@account)
      is_expected.to render_template('members')
    end

  end


  context 'show_statement', :timecop_freeze, :if => Account.config.using_statements? do

    before :each do
      @method=:get
      @action=:show_statement

      2.times do
        @statement=FactoryGirl.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :account => @account)
        Timecop.travel(1.second.from_now) # need different timestamp on statement
      end

      @params = { facility_id: facility.url_name, account_id: @account.id }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it 'should show statements list' do
      @params[:statement_id]='list'
      maybe_grant_always_sign_in :director
      do_request
      expect(assigns(:account)).to eq(@account)
      expect(assigns(:facility)).to eq(@authable)
      expect(assigns(:statements)).to be_kind_of(ActiveRecord::Relation)
      expect(assigns(:statements).count).to eq(2)
      is_expected.to render_template 'show_statement_list'
    end


    it 'should show statement PDF' do
      @params[:statement_id]=@statement.id
      @params[:format]='pdf'
      maybe_grant_always_sign_in :director
      do_request
      expect(assigns(:account)).to eq(@account)
      expect(assigns(:facility)).to eq(@authable)
      expect(assigns(:statement)).to eq(@statement)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body).to match(/%PDF-1.3/)
      is_expected.to render_template 'statements/show'
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
        expect(assigns(:account)).to eq(@account)
        is_expected.to set_flash
        expect(assigns(:account)).to be_suspended
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
        expect(assigns(:account)).to eq(@account)
        is_expected.to set_flash
        expect(assigns(:account)).not_to be_suspended
        assert_redirected_to facility_account_path(@authable, @account)
      end

    end
  end

end
