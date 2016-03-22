require "rails_helper"
require "controller_spec_helper"
require "transaction_search_spec_helper"

RSpec.describe AccountsController do
  render_views

  it "should route" do
    expect(get: "/accounts").to route_to(controller: "accounts", action: "index")
    expect(get: "/accounts/1").to route_to(controller: "accounts", action: "show", id: "1")
    expect(get: "/accounts/1/user_search").to route_to(controller: "accounts", action: "user_search", id: "1")
  end

  before(:all) { create_users }

  before(:each) do
    @authable = create_nufs_account_with_owner
  end

  context "index" do

    before(:each) do
      @method = :get
      @action = :index
    end

    it_should_require_login

    it "should list accounts, with edit account links for account owner" do
      create_nufs_account_with_owner
      maybe_grant_always_sign_in(:owner)
      do_request
      # should find 2 account users, with user roles 'Owner'
      expect(assigns[:account_users].collect(&:user_id)).to eq([@owner.id, @owner.id])
      expect(assigns[:account_users].collect(&:user_role)).to eq(%w(Owner Owner))
      # should show 2 accounts, with 'edit account' links
      expect(response).to render_template("accounts/index")
    end

    it_should_allow :purchaser do
      # should find 1 account user, with user roles as 'Purchaser'
      expect(assigns[:account_users].collect(&:user_id)).to eq([@purchaser.id])
      expect(assigns[:account_users].collect(&:user_role)).to eq(["Purchaser"])
      # should show 1 account, with no 'edit account' links
      expect(response).to render_template("accounts/index")
    end
  end

  context "show" do

    before :each do
      @method = :get
      @action = :show
      @params = { id: @authable.id }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      expect(assigns(:account)).to eq(@authable)
      expect(response).to render_template("accounts/show")
    end
  end

  context "user_search" do

    before :each do
      @method = :get
      @action = :user_search
      @params = { id: @authable.id }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      expect(assigns(:account)).to eq(@authable)
      expect(response).to render_template("account_users/user_search")
    end

  end

  context "transactions" do
    before :each do
      @method = :get
      @action = :transactions
      @params = { id: @authable.id }
      @user = @authable.owner.user
    end
    it_should_require_login
    it_should_deny :purchaser
    it_should_allow :owner do
      expect(assigns(:account)).to eq(@authable)
      expect(assigns[:order_details].where_values_hash).to eq("account_id" => @authable.id)
      # @authable is an nufs account, so it doesn't have a facility
      expect(assigns[:facility]).to be_nil
    end

    it_should_support_searching

  end

  context "transactions_in_review" do
    before :each do
      @method = :get
      @action = :transactions_in_review
      @params = { id: @authable.id }
      @user = @authable.owner.user
    end
    it_should_support_searching

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      expect(assigns[:account]).to eq(@authable)
      expect(assigns[:order_details].where_values_hash).to be_has_key(:account_id)
      expect(assigns[:order_details].where_values_hash[:account_id]).to eq(@authable.id)
      expect(assigns[:facility]).to be_nil
    end

    it "should use reviewed_at" do
      sign_in @user
      do_request
      expect(response).to be_success
      expect(assigns[:extra_date_column]).to eq(:reviewed_at)
      expect(assigns[:order_details].to_sql).to be_include("order_details.reviewed_at >")
    end

    it "should add dispute links" do
      sign_in @user
      do_request
      expect(response).to be_success
      allow_any_instance_of(OrderDetail).to receive(:can_dispute?).and_return(true)
      expect(assigns[:order_detail_link]).not_to be_nil
      expect(assigns[:order_detail_link][:text]).to eq("Dispute")
      expect(assigns[:order_detail_link][:display?].call(OrderDetail.new)).to be true
    end

  end

  context "suspension", if: SettingsHelper.feature_on?(:suspend_accounts) do
    before :each do
      @account = @authable
    end

    context "suspend" do
      before :each do
        @method = :get
        @action = :suspend
        @params = { account_id: @account.id }
      end

      it_should_require_login

      it_should_deny_all [:purchaser]

      it_should_allow_all [:owner, :business_admin] do
        expect(assigns(:account)).to eq(@account)
        is_expected.to set_flash
        expect(@account.reload).to be_suspended
        assert_redirected_to account_path(@account)
      end
    end

    context "unsuspend" do
      before :each do
        @method = :get
        @action = :unsuspend
        @params = { account_id: @account.id }
      end

      it_should_require_login

      it_should_deny_all [:purchaser]

      it_should_allow_all [:owner, :business_admin] do
        expect(assigns(:account)).to eq(@account)
        is_expected.to set_flash
        expect(assigns(:account)).not_to be_suspended
        assert_redirected_to account_path(@account)
      end
    end
  end

end
