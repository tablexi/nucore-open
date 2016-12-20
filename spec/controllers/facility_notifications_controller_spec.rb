require "rails_helper"
require "controller_spec_helper"
require "transaction_search_spec_helper"

RSpec.describe FacilityNotificationsController do

  before(:all) { create_users }
  render_views

  before :each do
    Settings.billing.review_period = 7.days
    @authable = FactoryGirl.create(:facility)
    @user = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
    @authable_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @params = { facility_id: @authable.url_name }

    @order_detail1 = place_and_complete_item_order(@user, @authable, @account)
    @order_detail2 = place_and_complete_item_order(@user, @authable, @account)

    @account2 = FactoryGirl.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
    @authable_account2 = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @order_detail3 = place_and_complete_item_order(@user, @authable, @account2)
  end
  after :each do
    Settings.reload!
  end
  def self.it_should_404_for_zero_day_review
    it "should 404 for zero day review" do
      Settings.billing.review_period = 0.days
      sign_in @admin
      do_request
      expect(response.code).to eq("404")
    end
  end

  context "index" do
    before :each do
      @method = :get
      @action = :index
    end
    it_should_deny_all [:staff, :senior_staff]
    it_should_404_for_zero_day_review

    it_should_allow_managers_only do
      expect(assigns(:order_details) - [@order_detail1, @order_detail2, @order_detail3]).to be_empty
      expect(assigns(:order_detail_action)).to eq(:send_notifications)
      is_expected.not_to set_flash
    end

    context "searching" do
      before :each do
        @user = @admin
      end
      it_should_support_searching
    end

  end

  context "send_notifications" do
    before :each do
      Notifier.deliveries.clear
      @method = :post
      @action = :send_notifications
      @params.merge!(order_detail_ids: [@order_detail1.id, @order_detail2.id])
    end

    it_should_404_for_zero_day_review

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_managers_only :redirect do
      expect(assigns(:errors)).to be_empty
      expect(assigns(:accounts_to_notify)).to contain_exactly(@account.id)
      expect([@order_detail1, @order_detail2]).to be_all { |od| od.reload.reviewed_at > 6.days.from_now }

      expect(Notifier.deliveries.count).to eq(1)
    end

    context "multiple accounts" do
      before :each do
        @params.merge!(order_detail_ids: [@order_detail1.id, @order_detail2.id, @order_detail3.id])
      end

      it_should_allow_managers_only :redirect do
        expect(assigns(:errors)).to be_empty
        expect([@order_detail1, @order_detail2, @order_detail3]).to be_all { |od| od.reload.reviewed_at? }
        expect(assigns(:accounts_to_notify)).to contain_exactly(@account.id, @account2.id)
      end

      context "while signed in" do
        before :each do
          maybe_grant_always_sign_in(:admin)
        end

        it "sends one email for the two accounts" do
          expect { do_request }.to change { Notifier.deliveries.count }.by(1)
        end

        it "should display the account list if less than 10 accounts" do
          @accounts = FactoryGirl.create_list(:nufs_account, 3, account_users_attributes: account_users_attributes_hash(user: @user))
          @authable_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
          @params = { facility_id: @authable.url_name }

          @order_details = @accounts.map do |account|
            place_and_complete_item_order(@user, @authable, account)
          end

          @params[:order_detail_ids] = @order_details.map(&:id)
          do_request
          is_expected.to set_flash
          expect(@accounts).to be_all { |account| flash[:notice].include? account.account_number }
        end

        it "should display a count if more than 10 accounts notified" do
          @accounts = FactoryGirl.create_list(:nufs_account, 11, account_users_attributes: account_users_attributes_hash(user: @user))
          @authable_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
          @params = { facility_id: @authable.url_name }

          @order_details = @accounts.map do |account|
            place_and_complete_item_order(@user, @authable, account)
          end

          @params[:order_detail_ids] = @order_details.map(&:id)

          do_request

          is_expected.to set_flash
          expect(flash[:notice]).to include("11 accounts")
        end
      end
    end

    context "errors" do
      before { maybe_grant_always_sign_in(:admin) }

      it "should display an error for no orders" do
        @params[:order_detail_ids] = nil
        do_request
        expect(flash[:error]).not_to be_nil
        expect(response).to be_redirect
      end

      it "should return an error message for order not found in list" do
        @params[:order_detail_ids] = [0]
        do_request
        expect(flash[:error]).to include("0")
      end
    end
  end

  context "in review" do
    before :each do
      @method = :get
      @action = :in_review
      @order_detail1.reviewed_at = 7.days.from_now
      @order_detail1.save!
      @order_detail3.reviewed_at = 7.days.from_now
      @order_detail3.save!
    end

    it_should_deny_all [:staff, :senior_staff]
    it_should_404_for_zero_day_review

    it_should_allow_managers_only do
      expect(assigns(:order_details) - [@order_detail1, @order_detail3]).to be_empty
      expect(assigns(:order_detail_action)).to eq(:mark_as_reviewed)
      is_expected.not_to set_flash
    end

    context "searching" do
      before :each do
        @user = @admin
      end
      it_should_support_searching
    end
  end

  context "mark as reviewed" do
    before :each do
      @method = :post
      @action = :mark_as_reviewed
      maybe_grant_always_sign_in(:admin)
    end

    it_should_deny_all [:staff, :senior_staff]
    it_should_404_for_zero_day_review

    it "should update" do
      @params[:order_detail_ids] = [@order_detail1.id, @order_detail3.id]
      do_request
      expect(flash[:error]).to be_nil
      expect(assigns(:order_details_updated)).to eq([@order_detail1, @order_detail3])
      expect(@order_detail1.reload.reviewed_at.to_i).to eq(Time.zone.now.to_i)
      expect(@order_detail3.reload.reviewed_at.to_i).to eq(Time.zone.now.to_i)
    end

    it "should display an error for no orders" do
      do_request
      expect(flash[:error]).not_to be_nil
    end
  end

end
