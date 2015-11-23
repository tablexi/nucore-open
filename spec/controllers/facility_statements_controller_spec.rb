require "rails_helper"
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

if Account.config.statements_enabled?

  RSpec.describe FacilityStatementsController do
    render_views

    def create_order_details
      @order_detail1 = place_and_complete_item_order(@user, @authable, @account)
      @order_detail2 = place_and_complete_item_order(@user, @authable, @account)
      @order_detail2.update_attributes(:reviewed_at => nil)

      @account2=FactoryGirl.create(@account_sym, :account_users_attributes => account_users_attributes_hash(:user => @user), :facility_id => @authable.id)
      @authable_account2 = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @order_detail3 = place_and_complete_item_order(@user, @authable, @account2)

      [@order_detail1, @order_detail3].each do |od|
        od.reviewed_at = 1.day.ago
        od.save!
      end

    end

    before(:all) do
      create_users
      @account_type = Account.config.statement_account_types.first
      @account_sym = @account_type.underscore.to_sym
    end

    before(:each) do
      @authable=FactoryGirl.create(:facility)
      @user=FactoryGirl.create(:user)
      UserRole.grant(@user, UserRole::ADMINISTRATOR)
      @account=FactoryGirl.create(@account_sym, :account_users_attributes => account_users_attributes_hash(:user => @user), :facility_id => @authable.id)
      @statement=FactoryGirl.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :account => @account)
      @params={ :facility_id => @authable.url_name }
    end


    context 'index' do

      before :each do
        @method=:get
        @action=:index
      end

      it_should_allow_managers_only do
        expect(assigns(:statements).size).to eq(1)
        expect(assigns(:statements)[0]).to eq(@statement)
        is_expected.not_to set_flash
      end

      it_should_deny_all [:staff, :senior_staff]

    end

    context "new" do
      before :each do
        @method = :get
        @action = :new
        create_order_details
      end

      it_should_allow_managers_only do
        expect(response).to be_success
      end

      it_should_deny_all [:staff, :senior_staff]

      it "should return the right order details" do
        grant_and_sign_in(@user)
        do_request
        expect(response).to be_success
        expect(assigns(:accounts)).to contain_all [@account, @account2]
        expect(assigns(:facility)).to eq(@authable)
        expect(assigns(:order_detail_action)).to eq(:send_statements)
        expect(assigns(:order_details)).to contain_all [@order_detail1, @order_detail3]
      end

      it_should_support_searching
    end

    context "send_statements" do
      before :each do
        create_order_details
        @method=:post
        @action=:send_statements
        @params.merge!({:order_detail_ids => [@order_detail1.id, @order_detail3.id]})
      end

      it_should_allow_managers_only :redirect do
        expect(response).to be_redirect
      end

      it_should_deny_all [:staff, :senior_staff]

      it "should create and send statements" do
        expect(@order_detail1.reload.reviewed_at).to be < Time.zone.now
        expect(@order_detail1.statement).to be_nil
        expect(@order_detail1.price_policy).not_to be_nil
        expect(@order_detail1.account.type).to eq(@account_type)
        expect(@order_detail1.dispute_at).to be_nil

        grant_and_sign_in(@user)
        do_request
        expect(flash[:error]).to be_nil
        expect(assigns(:account_statements)).to have_key(@account)
        expect(assigns(:account_statements)).to have_key(@account2)
        expect(response).to redirect_to :action => :new
      end

      context "errors" do
        it "should display an error for no orders" do
          @params[:order_detail_ids] = nil
          grant_and_sign_in(@user)
          do_request
          expect(flash[:error]).not_to be_nil
          expect(response).to redirect_to :action => :new
        end
      end
    end

    context 'show' do

      before :each do
        @method=:get
        @action=:show
        @params.merge!(:id => @statement.id)
      end

      it_should_allow_managers_only { expect(assigns(:statement)).to eq(@statement) }

      it_should_deny_all [:staff, :senior_staff]

    end

  end
end
