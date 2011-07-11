require 'spec_helper'; require 'controller_spec_helper'

describe FacilityStatementsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @user=Factory.create(:user)
    @account=Factory.create(:credit_card_account, :account_users_attributes => [Hash[:user => @owner, :created_by => @user, :user_role => 'Owner']])
    @statement=Factory.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :account => @account)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_managers_only do
      assigns(:statements).size.should == 1
      assigns(:statements)[0].should == @statement
      should_not set_the_flash
    end

  end


  context 'pending' do

    before :each do
      @method=:get
      @action=:pending
    end

    it_should_allow_managers_only do
      assigns[:acct2ods].should be_empty
    end

    context 'with reviewed order' do

      before :each do
        place_and_complete_item_order(@owner, @authable, @account, true)
      end

      it_should_allow :director, 'to populate an account to order details data structure' do
        assigns[:acct2ods].size.should == 1
        assigns[:acct2ods].keys[0].should == @account
        assigns[:acct2ods][@account].should be_kind_of Array
        assigns[:acct2ods][@account].size.should == 1
        assigns[:acct2ods][@account][0].should == @order_detail
      end
    end

  end


  context 'email' do

    before :each do
      @method=:post
      @action=:email
    end

    it_should_allow_managers_only :redirect

  end


  context 'accounts_receivable' do

    before :each do
      @method=:get
      @action=:accounts_receivable
    end

    it_should_allow_managers_only

  end


  context 'show' do

    before :each do
      @method=:get
      @action=:show
      @params.merge!(:id => @statement.id)
    end

    it_should_allow_managers_only { assigns(:statement).should == @statement }

  end

end
