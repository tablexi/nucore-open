require "rails_helper"

RSpec.describe TransactionSearch do
  let(:account) { @account }
  let(:facility) { @authable }
  let(:order_detail_complete) { @order_detail_complete }
  let(:order_detail_new) { @order_detail_new }
  let(:user) { @user }

  class TransactionSearcher < ApplicationController
    attr_reader :facility, :facilities, :account, :accounts, :account_owners, :products, :order_statuses
    attr_writer :facility, :account
    # give us a way to set the user
    attr_accessor :session_user, :order_details

    include TransactionSearch
    def params
      @params
    end
    def params=(params)
      @params = params
    end

    def all_order_details_with_search
      # everything that needs to be done will be done by the module
    end
  end

  before :each do
    ignore_order_detail_account_validations
    @user = FactoryGirl.create(:user)
    @staff = FactoryGirl.create(:user, :username => "staff")
    @staff2 = FactoryGirl.create(:user, :username => "staff2")
    UserRole.grant(@staff, UserRole::FACILITY_DIRECTOR)
    @controller = TransactionSearcher.new
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @price_group      = @authable.price_groups.create(FactoryGirl.attributes_for(:price_group))
    @account          = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @staff))
    @order            = @staff.orders.create(FactoryGirl.attributes_for(:order, :created_by => @staff.id, :account => @account, :ordered_at => Time.now))
    @item             = @authable.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    @order_detail_complete = place_and_complete_item_order(@user, @authable, @account)
    @order_detail_new = place_product_order(@staff, @authable, @item)

    # fake signing in as staff
    @controller.session_user = @staff
    @controller.response = ActionDispatch::Response.new
    @controller.request = ActionDispatch::Request.new('rack.input' => StringIO.new, content_type: 'html')
  end

  context "wrapping" do
    it "responds to all_order_details" do
      expect(@controller).to respond_to(:all_order_details)
    end
  end

  context "field populating" do
    context "with facility" do
      before :each do
        @controller.params = { :facility_id => @authable.url_name }
        @controller.init_current_facility
      end

      it "should populate facility" do
        @controller.all_order_details
        expect(@controller.current_facility).to eq(@authable)
        expect(@controller.facilities).to eq([@authable])
      end

      it "should populate accounts" do
        @controller.all_order_details
        expect(@controller.account).to be_nil
        expect(@controller.accounts).to eq([@account])
      end

      it "populates accounts based off order_details, not orders" do
        @account2 = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @staff))
        Order.all.each { |o| o.update_attributes!(:account => @account) }
        OrderDetail.all.each { |od| od.update_attributes!(:account => @account2)}
        expect(@order.reload.account).to eq(@account)
        @controller.all_order_details
        expect(@controller.accounts).to eq([@account2])
      end

      it "populates owners based off of order_details, not orders" do
        @account2 = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @staff2))
        Order.all.each { |o| o.update_attributes!(:account => @account) }
        OrderDetail.all.each { |od| od.update_attributes!(:account => @account2) }
        expect(@order.reload.account.owner.user).to eq(@staff)
        @controller.all_order_details
        expect(@controller.account_owners).to eq([@staff2])
      end

      it "should not populate an account for another facility" do
        @facility2 = FactoryGirl.create(:facility)
        @account2 = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @staff))

        @controller.all_order_details
        expect(@controller.current_facility).to eq(@authable)
        expect(@controller.account).to be_nil
        expect(@controller.accounts).to eq([@account])
      end
      it "should populate order statuses" do
        @controller.all_order_details
        expect(@controller.order_statuses).to contain_all [@os_new, @os_complete]
      end
    end

    context "with account" do
      before :each do
        @facility2 = FactoryGirl.create(:facility)
        @credit_account = FactoryGirl.create(:nufs_account, :facility_id => @facility2.id, :account_users_attributes => account_users_attributes_hash(:user => @staff))
        @facility_account2 = @facility2.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
        @item2             = @facility2.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account2.id))
        @order_detail2 = place_and_complete_item_order(@user, @facility2, @credit_account)
      end

      it "should pull all facilities for nufs account that have transactions" do
        # @account needs to have an order detail for it to show up
        @order_detail3 = place_and_complete_item_order(@user, @facility2, @account)
        @controller.params = { :account_id => @account.id }
        @controller.init_current_account
        @controller.all_order_details
        expect(@controller.current_facility).to be_nil
        expect(@controller.account).to eq(@account)
        expect(@controller.facilities).to contain_all [@authable, @facility2]
      end
      it "should only have a single facility for credit card" do
        @controller.params = { :account_id => @credit_account.id }
        @controller.init_current_account
        @controller.all_order_details
        expect(@controller.current_facility).to be_nil
        expect(@controller.account).to eq(@credit_account)
        expect(@controller.facilities).to eq([@facility2])
      end
    end
    context "account owners" do
      before :each do
        @user2 = FactoryGirl.create(:user)
        @user3 = FactoryGirl.create(:user)
        @account2 = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @user2))
        # account 2 needs to have an order detail for it to show up
        place_and_complete_item_order(@user2, @authable, @account2)
      end
      it "should populate account owners" do
        @controller.params = { :facility_id => @authable.url_name }
        @controller.init_current_facility
        @controller.all_order_details
        expect(@controller.account_owners).to contain_all [@staff, @user2]
      end
    end

    context "products" do
      before :each do
        @facility2 = FactoryGirl.create(:facility)
        @instrument = FactoryGirl.create(:instrument,
                                      :facility => @authable,
                                      :facility_account => @facility_account)
        @service = @authable.services.create(FactoryGirl.attributes_for(:service, :facility_account_id => @facility_account.id))
        @other_item = @facility2.instruments.create(FactoryGirl.attributes_for(:item))
        # each product needs to have an order detail for it to show up
        [@item, @instrument, @service].each do |product|
          place_product_order(@staff, @authable, product, @account)
        end

        @controller.params = { :facility_id => @authable.url_name }
        @controller.init_current_facility
        @controller.all_order_details
      end
      it "should populate products" do
        expect(@controller.products).to contain_all [@item, @instrument, @service]
      end
    end
  end

  shared_context "it filters by order status" do |date_range_field|
    let(:params) do
      { facility_id: facility.url_name, date_range_field: date_range_field }
    end

    before :each do
      expect(order_detail_complete.order_status).to eq @os_complete
      expect(order_detail_new.order_status).to eq @os_new
      @controller.params = params
      @controller.init_current_facility
      @controller.params.merge!(order_statuses: order_statuses)
      @controller.all_order_details
    end

    context "with no order statuses specified" do
      let(:order_statuses) { nil }

      it "returns all" do
        expect(@controller.order_details)
          .to contain_all [order_detail_new, order_detail_complete]
      end
    end

    context "with new status specified" do
      let(:order_statuses) { [@os_new.id] }

      it "returns only new order_details" do
        expect(@controller.order_details).to eq [order_detail_new]
      end
    end

    context "with complete status specified" do
      let(:order_statuses) { [@os_complete.id] }

      it "returns only complete order_details" do
        expect(@controller.order_details).to eq [order_detail_complete]
      end
    end
  end

  context "searching" do
    context "when filtering by date range" do
      before :each do
        allow(order_detail_new).to receive(:total).and_return(100)
        order_detail_new.update_attribute(:fulfilled_at, Time.zone.now)
        allow(order_detail_complete).to receive(:total).and_return(100)
        order_detail_complete.update_attribute(:fulfilled_at, Time.zone.now)
      end

      context "using fulfilled_at date" do
        it_behaves_like "it filters by order status", :fulfilled_at
      end

      context "using journal_or_statement_date" do
        let(:journal) do
          Journal.create!(
            created_by: user.id,
            facility_id: facility.id,
            journal_date: Time.zone.now,
          )
        end

        before :each do
          order_detail_new.update_attribute(:account_id, account.id)
          journal.create_journal_rows!([order_detail_new, order_detail_complete])
        end

        it_behaves_like "it filters by order status", :journal_or_statement_date
      end

      context "using ordered_at date" do
        it_behaves_like "it filters by order status", :ordered_at
      end
    end
  end
end
