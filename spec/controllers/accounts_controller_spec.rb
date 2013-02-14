require 'spec_helper'
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

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
  
  context 'transactions' do
    before :each do
      @method = :get
      @action = :transactions
      @params = { :id => @authable.id }
      @user = @authable.owner.user
    end
    it_should_require_login
    it_should_deny :purchaser
    it_should_allow :owner do
      assigns(:account).should == @authable
      assigns[:order_details].where_values_hash.should == { :account_id => @authable.id }
      # @authable is an nufs account, so it doesn't have a facility
      assigns[:facility].should be_nil
    end
    
    it_should_support_searching
    
  end
  
  context 'transactions_in_review' do
    before :each do
      @method = :get
      @action = :transactions_in_review
      @params = { :id => @authable.id }
      @user = @authable.owner.user
    end
    it_should_support_searching
    
    it_should_require_login
    
    it_should_deny :purchaser
    
    it_should_allow :owner do
      assigns[:account].should == @authable
      assigns[:order_details].where_values_hash.should be_has_key(:account_id)
      assigns[:order_details].where_values_hash[:account_id].should == @authable.id
      assigns[:facility].should be_nil
    end
    
    it "should use reviewed_at" do
      sign_in @user
      do_request
      response.should be_success
      assigns[:extra_date_column].should == :reviewed_at
      assigns[:order_details].to_sql.should be_include("order_details.reviewed_at >")
    end
    
    it "should add dispute links" do
      sign_in @user
      do_request
      response.should be_success
      OrderDetail.any_instance.stub(:can_dispute?).and_return(true)
      assigns[:order_detail_link].should_not be_nil
      assigns[:order_detail_link][:text].should == "Dispute"
      assigns[:order_detail_link][:display?].call(OrderDetail.new).should be_true
    end
    
    
  end
  


  context "POST /accounts/create" do
    it "should 403 unless class_type is legit"
  end

end

