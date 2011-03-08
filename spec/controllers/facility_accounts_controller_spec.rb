require 'spec_helper'; require 'controller_spec_helper'

describe FacilityAccountsController do
  integrate_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @item=Factory.create(:item, :facility_account => @facility_account, :facility => @authable)
    @account=Factory.create(:nufs_account)
    grant_role(@purchaser, @account)
    grant_role(@owner, @account)
    @order=Factory.create(:order, :user => @purchaser, :created_by => @purchaser.id)
    @order_detail=Factory.create(:order_detail, :product => @item, :order => @order, :account => @account)
  end


  context 'index' do

    before(:each) do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      should assign_to(:accounts).with_kind_of(Array)
      assigns(:accounts).size.should == 1
      assigns(:accounts)[0].should == @account
      should render_template('index.html.haml')
    end

  end


  context 'show' do

    before(:each) do
      @method=:get
      @action=:show
      @params={ :facility_id => @authable.url_name, :id => @account.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should render_template('show.html.haml')
    end

  end


  context 'new' do

    before(:each) do
      @method=:get
      @action=:new
      @params={ :facility_id => @authable.url_name, :owner_user_id => @owner.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:owner_user).should == @owner
      assigns(:account).should be_new_record
      assigns(:account).expires_at.should_not be_nil
      should render_template('new.html.haml')
    end

  end


  context 'edit' do

    before(:each) do
      @method=:get
      @action=:edit
      @params={ :facility_id => @authable.url_name, :id => @account.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should render_template('edit.html.haml')
    end

  end


  context 'update' do

    before(:each) do
      @method=:put
      @action=:update
      @params={
        :facility_id => @authable.url_name,
        :id => @account.id,
        :account => Factory.attributes_for(:nufs_account)
      }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should set_the_flash
      assert_redirected_to facility_account_url
    end

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @acct_attrs=Factory.attributes_for(:nufs_account)
      @params={
        :facility_id => @authable.url_name,
        :id => @account.id,
        :owner_user_id => @owner.id,
        :account => @acct_attrs,
        :class_type => 'NufsAccount'
      }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do |user|
      should assign_to(:account).with_kind_of(NufsAccount)
      assigns(:account).account_number.should == @acct_attrs[:account_number]
      assigns(:account).created_by.should == user.id
      assigns(:account).account_users.size.should == 1
      assigns(:account).account_users[0] == @owner
      # saving with NufsAccount will fail because expires_at will never
      # be set. That's because the nucs tables aren't mocked. We're not
      # testing nucs here so take the opportunity to test save fails handling
      should render_template('new.html.haml')
    end


    context 'PurchaseOrderAccount' do

      before :each do
        @params[:class_type]='PurchaseOrderAccount'
        @acct_attrs=Factory.attributes_for(:purchase_order_account)
        @params[:account]=@acct_attrs
      end

      it_should_allow :director do
        assigns(:account).facility_id.should == @authable.id
        should set_the_flash
        assert_redirected_to user_accounts_url(@authable, @owner)
      end

    end


    context 'CreditCardAccount' do

      before :each do
        @params[:class_type]='CreditCardAccount'
        @acct_attrs=Factory.attributes_for(:credit_card_account)
        @params[:account]=@acct_attrs
      end

      it_should_allow :director do
        assigns(:account).expires_at.should_not be_nil
      end

    end

  end


  context 'new_account_user_search' do

    before :each do
      @method=:get
      @action=:new_account_user_search
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      should render_template 'new_account_user_search.html.haml'
    end

  end


  context 'user_search' do

    before :each do
      @method=:get
      @action=:user_search
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      should render_template 'user_search.html.haml'
    end

  end


  context 'search' do

    before :each do
      @method=:get
      @action=:search
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      should render_template 'search.html.haml'
    end

  end


  context 'search_results' do

    before :each do
      @method=:get
      @action=:search_results
      @params={ :facility_id => @authable.url_name, :search_term => @guest.username }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:users).size.should == 1
      assigns(:users)[0].should == @guest
      should render_template('search_results.html.haml')
    end


    context 'POST' do

      before(:each) { @method=:post }

      it_should_allow :director do
        assigns(:users).size.should == 1
        should render_template('search_results.html.haml')
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

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:user).should == @guest
      should render_template('user_accounts.html.haml')
    end

  end


  context 'credit_cards' do

    before :each do
      @method=:get
      @action=:credit_cards
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      should assign_to(:subnav)
      should assign_to(:active_tab)
      should assign_to(:accounts).with_kind_of(Array)
      should set_the_flash #no accounts found
      should render_template('credit_cards.html.haml')
    end

    it 'should test what happens when CreditCardAccount#facility_balance is > 0'

  end


  context 'update_credit_cards' do

    before :each do
      @method=:post
      @action=:update_credit_cards
      @ccact=Factory.build(:credit_card_account)
      @ccact.account_users_attributes = [{:user_id => @owner.id, :user_role => AccountUser::ACCOUNT_OWNER, :created_by => @admin.id }]
      assert @ccact.save
      @params={
        :facility_id => @authable.url_name,
        :account => {
          @ccact.id.to_s => {
            :reference => 'xyz123',
            :transaction_amount => '12.34',
            :notes => 'this transaction is fake'
          }
        }
      }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do |user|
      should assign_to(:subnav)
      should assign_to(:active_tab)
      assigns(:error_fields).should be_empty
      should set_the_flash
      assert_redirected_to credit_cards_facility_accounts_path
      pat=@ccact.reload.payment_account_transactions[0]
      pat.facility_id.should == @authable.id
      pat.created_by.should == user.id
      pat.finalized_at.should_not be_nil
      pat.is_in_dispute.should == false
      ccid=@ccact.id.to_s
      pat.description.should == @params[:account][ccid][:notes]
      pat.reference.should == @params[:account][ccid][:reference]
      pat.transaction_amount.should == @params[:account][ccid][:transaction_amount].to_f * -1
    end

    it 'should test multiple cards sent in one POST'
    it 'should test transaction failure'

  end


  context 'purchase_orders' do

    before :each do
      @method=:get
      @action=:purchase_orders
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      should assign_to(:subnav)
      should assign_to(:active_tab)
      should assign_to(:accounts).with_kind_of(Array)
      should set_the_flash #no accounts found
      should render_template('purchase_orders.html.haml')
    end

    it 'should test what happens when PurchaseOrderAccount#facility_balance is > 0'

  end


  context 'update_purchase_orders' do

    before :each do
      @method=:post
      @action=:update_purchase_orders
      @poact=Factory.build(:purchase_order_account)
      @poact.account_users_attributes = [{:user_id => @owner.id, :user_role => AccountUser::ACCOUNT_OWNER, :created_by => @admin.id }]
      assert @poact.save
      @params={
        :facility_id => @authable.url_name,
        :account => {
          @poact.id.to_s => {
            :reference => 'xyz123',
            :transaction_amount => '12.34',
            :notes => 'this transaction is fake'
          }
        }
      }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do |user|
      should assign_to(:subnav)
      should assign_to(:active_tab)
      assigns(:error_fields).should be_empty
      should set_the_flash
      assert_redirected_to purchase_orders_facility_accounts_path
      pat=@poact.reload.payment_account_transactions[0]
      pat.facility_id.should == @authable.id
      pat.created_by.should == user.id
      pat.finalized_at.should_not be_nil
      pat.is_in_dispute.should == false
      poid=@poact.id.to_s
      pat.description.should == @params[:account][poid][:notes]
      pat.reference.should == @params[:account][poid][:reference]
      pat.transaction_amount.should == @params[:account][poid][:transaction_amount].to_f * -1
    end

    it 'should test multiple purchase orders sent in one POST'
    it 'should test transaction failure'

  end


  context 'members' do

    before :each do
      @method=:get
      @action=:members
      @params={ :facility_id => @authable.url_name, :account_id => @account.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should render_template('members.html.haml')
    end

  end


  context 'show_statement' do

    before :each do
      @method=:get
      @action=:show_statement

      2.times do
        @statement=Factory.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :invoice_date => Time.zone.now)
        @transact=Factory.create(:payment_account_transaction, {
          :facility_id => @authable.id,
          :created_by => @admin.id,
          :account_id => @account.id,
          :statement_id => @statement.id
        })
        sleep 1 # need different timestamp on statement
      end

      @params={ :facility_id => @authable.url_name, :account_id => @account.id, :statement_id => @statement.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      assigns(:facility).should == @authable
      assigns(:statement).should == @statement
      should assign_to(:statements).with_kind_of Array
      should assign_to(:prev_statement).with_kind_of Statement
      should assign_to(:new_payments).with_kind_of Float
      should assign_to(:new_purchases).with_kind_of Float
      assigns(:account_txns)[0].should == @transact
      should assign_to(:balance_prev).with_kind_of Float
      should assign_to(:balance_due).with_kind_of Float
      should render_template 'show_statement'
    end


    context 'recent statement id' do

      before :each do
        @params[:statement_id]='recent'
      end

      it_should_allow_all facility_managers do
        assigns(:statement).should be_nil
        should render_template 'show_statement'
      end
    end

  end


  context 'suspend' do

    before :each do
      @method=:get
      @action=:suspend
      @params={ :facility_id => @authable.url_name, :account_id => @account.id }
    end

    it_should_require_login

    it_should_deny :staff

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

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should set_the_flash
      assert_redirected_to facility_account_path(@authable, @account)
    end

  end

end
