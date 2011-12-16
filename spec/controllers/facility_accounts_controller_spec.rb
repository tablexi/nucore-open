require 'spec_helper'; require 'controller_spec_helper'

describe FacilityAccountsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @item=Factory.create(:item, :facility_account => @facility_account, :facility => @authable)
    @account=create_nufs_account_with_owner
    grant_role(@purchaser, @account)
    grant_role(@owner, @account)
    @order=Factory.create(:order, :user => @purchaser, :created_by => @purchaser.id, :facility => @authable)
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

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should render_template('show')
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

    it_should_deny :staff

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
        :account => Factory.attributes_for(:nufs_account)
      }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      assigns(:account).affiliate.should be_nil
      assigns(:account).affiliate_other.should be_nil
      should set_the_flash
      assert_redirected_to facility_account_url
    end

    context 'with affiliate' do

      before :each do
        user=Factory.create(:user)

        owner={
          :user => user,
          :created_by => user,
          :user_role => 'Owner'
        }

        account_attrs={
          :created_by => user,
          :account_users_attributes => [owner],
        }

        @account=Factory.create(:purchase_order_account, account_attrs)

        @params[:id]=@account.id
        @params[:class_type]='PurchaseOrderAccount'
        @params[:account]=@account.attributes
        @params[:account][:affiliate]=Affiliate::OTHER.name
        @params[:account]['affiliate_other']='Jesus Charisma'
      end

      it_should_allow :director, 'to change affiliate to other' do
        assigns(:account).should == @account
        assigns(:account).affiliate.should == Affiliate::OTHER
        assigns(:account).affiliate_other.should == @params[:account]['affiliate_other']
        should set_the_flash
        assert_redirected_to facility_account_url
      end

      context 'not other' do

        before :each do
          @affiliate=Affiliate.create!(:name => 'Rod Blagojevich')
          @params[:account][:affiliate]=@affiliate.name
        end

        it_should_allow :director do
          assigns(:account).should == @account
          assigns(:account).affiliate.should == @affiliate
          assigns(:account).affiliate_other.should be_nil
          should set_the_flash
          assert_redirected_to facility_account_url
        end

      end
    end

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @acct_attrs=Factory.attributes_for(:nufs_account)
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

    it_should_deny :staff

    it_should_allow_all facility_managers do |user|
      should assign_to(:account).with_kind_of(NufsAccount)
      assigns(:account).account_number.should == @acct_attrs[:account_number]
      assigns(:account).created_by.should == user.id
      assigns(:account).account_users.size.should == 1
      assigns(:account).account_users[0] == @owner
      assigns(:account).affiliate.should be_nil
      assigns(:account).affiliate_other.should be_nil
      # saving with NufsAccount will fail because expires_at will never
      # be set. That's because the nucs tables aren't mocked. We're not
      # testing nucs here so take the opportunity to test save fails handling
      should render_template('new')
    end


    context 'PurchaseOrderAccount' do

      before :each do
        @params[:class_type]='PurchaseOrderAccount'
        @acct_attrs=Factory.attributes_for(:purchase_order_account)
        @acct_attrs[:affiliate]=@acct_attrs[:affiliate].name
        @params[:account]=@acct_attrs
      end

      it_should_allow :director do
        assigns(:account).facility_id.should == @authable.id
        assigns(:account).should be_kind_of PurchaseOrderAccount
        assigns(:account).affiliate.name.should == @acct_attrs[:affiliate]
        assigns(:account).affiliate_other.should be_nil
        should set_the_flash
        assert_redirected_to user_accounts_url(@authable, @owner)
      end

    end


    context 'CreditCardAccount' do

      before :each do
        @params[:class_type]='CreditCardAccount'
        @acct_attrs=Factory.attributes_for(:credit_card_account)
        @acct_attrs[:affiliate]=@acct_attrs[:affiliate].name
        @params[:account]=@acct_attrs
      end

      it_should_allow :director do
        assigns(:account).expires_at.should_not be_nil
        assigns(:account).facility.id.should == @authable.id
        
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
      should render_template 'new_account_user_search'
    end

  end
  
  context 'accounts_receivable' do

    before :each do
      @method=:get
      @action=:accounts_receivable
      @params={:facility_id => @authable.url_name}
    end

    it_should_allow_managers_only

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
      should render_template 'user_search'
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
      should render_template 'search'
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
      should render_template('search_results')
    end


    context 'POST' do

      before(:each) { @method=:post }

      it_should_allow :director do
        assigns(:users).size.should == 1
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

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:user).should == @guest
      should render_template('user_accounts')
    end

  end


  context 'credit_cards with account' do

    before :each do
      ccact=Factory.build(:credit_card_account)
      prepare_for_account_show(:credit_cards, ccact)
      @params[:selected_account]=ccact.id
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      should assign_to(:subnav)
      should assign_to(:active_tab)
      should assign_to(:accounts).with_kind_of(Array)
      assigns[:selected].should == assigns[:accounts].first
      assigns[:unreconciled_details].should == OrderDetail.account_unreconciled(@authable, assigns[:selected])
      should render_template('credit_cards')
    end

    it 'should test selected_account param'

  end


  context 'credit_cards without account' do

    before :each do
      @method=:get
      @action=:credit_cards
      @params={ :facility_id => @authable.url_name }
    end

    it_should_allow :director do
      should assign_to(:subnav)
      should assign_to(:active_tab)
      assigns(:accounts).should be_empty
      should_not assign_to :selected
      should_not assign_to :unreconciled_details
      should render_template('credit_cards')
    end

  end


  context 'purchase_orders with account' do

    before :each do
      poact=Factory.build(:purchase_order_account)
      prepare_for_account_show(:purchase_orders, poact)
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      should assign_to(:subnav)
      should assign_to(:active_tab)
      should assign_to(:accounts).with_kind_of(Array)
      assigns[:selected].should == assigns[:accounts].first
      assigns[:unreconciled_details].should == OrderDetail.account_unreconciled(@authable, assigns[:selected])
      should render_template('purchase_orders')
    end

    it 'should test selected_account param'

  end


  context 'purchase_orders without account' do

    before :each do
      @method=:get
      @action=:purchase_orders
      @params={ :facility_id => @authable.url_name }
    end

    it_should_allow :director do
      should assign_to(:subnav)
      should assign_to(:active_tab)
      assigns(:accounts).should be_empty
      should_not assign_to :selected
      should_not assign_to :unreconciled_details
      should render_template('purchase_orders')
    end

  end


  context 'update_credit_cards' do

    before :each do
      ccact=Factory.build(:credit_card_account)
      prepare_for_account_update(:update_credit_cards, ccact)
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:error_fields).should be_empty
      should set_the_flash
      assert_redirected_to credit_cards_facility_accounts_path
      @order_detail.reload
      @order_detail.state.should == 'reconciled'
      @order_detail.reconciled_note.should_not be_nil
    end

    it 'should test multiple cards sent in one POST'
    it 'should test transaction failure'

  end


  context 'update_purchase_orders' do

    before :each do
      @poact=Factory.build(:purchase_order_account)
      prepare_for_account_update(:update_purchase_orders, @poact)
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do |user|
      assigns(:error_fields).should be_empty
      should set_the_flash
      assert_redirected_to purchase_orders_facility_accounts_path
      @order_detail.reload
      @order_detail.state.should == 'reconciled'
      @order_detail.reconciled_note.should_not be_nil
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
      should render_template('members')
    end

  end


  context 'show_statement' do

    before :each do
      @method=:get
      @action=:show_statement

      2.times do
        @statement=Factory.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :account => @account)
        sleep 1 # need different timestamp on statement
      end

      @params={ :facility_id => @authable.url_name, :account_id => @account.id, :statement_id => 'recent' }
    end

    it_should_require_login

    it_should_deny :staff

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


  private

  def prepare_for_account_update(action, account)
    @method=:post
    @action=action
    account.account_users_attributes = [{:user_id => @purchaser.id, :user_role => AccountUser::ACCOUNT_OWNER, :created_by => @admin.id }]
    assert account.save
    @price_policy=Factory.create(:item_price_policy, :item => @item, :price_group => @nupg)
    @price_group_product=Factory.create(:price_group_product, :product => @item, :price_group => @nupg, :reservation_window => nil)
    @order_detail.account=account
    @order_detail.assign_price_policy
    assert @order_detail.save

    @order_detail.change_status!(OrderStatus.complete.first)

    @params={
      :facility_id => @authable.url_name,
      :order_detail => {
        @order_detail.id.to_s => {
          :reconciled => '1',
          :notes => 'this transaction is fake'
        }
      }
    }
  end


  def prepare_for_account_show(action, account)
    @method=:get
    @action=action
    @params={ :facility_id => @authable.url_name }
    account.account_users_attributes = [{:user_id => @purchaser.id, :user_role => AccountUser::ACCOUNT_OWNER, :created_by => @admin.id }]
    assert account.save
    statement=Factory.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :account => account)
    @order_detail.to_complete!
    @order_detail.update_attributes(:account => account, :statement => statement, :fulfilled_at => Time.zone.now-1.day, :actual_cost => 10, :actual_subsidy => 2)
  end

end
