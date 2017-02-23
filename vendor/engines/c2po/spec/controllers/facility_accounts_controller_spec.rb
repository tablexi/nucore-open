require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityAccountsController do
  render_views

  let(:account) { @account }
  let(:facility) { facility_account.facility }
  let(:facility_account) { FactoryGirl.create(:facility_account) }
  let(:item) { FactoryGirl.create(:item, facility_account: facility_account) }
  let(:account_owner) { @owner }
  let(:purchaser) { @purchaser }

  before(:all) { create_users }

  before do
    @authable = facility # controller_spec_helper requires @authable to be set
    @account = FactoryGirl.create(:credit_card_account, account_users_attributes: [FactoryGirl.attributes_for(:account_user, user: account_owner)])
    grant_role(purchaser, @account)
    grant_role(account_owner, @account)
    order = FactoryGirl.create(:order, user: purchaser, created_by: purchaser.id, facility: facility)
    FactoryGirl.create(:order_detail, product: item, order: order, account: @account)
  end

  context "PUT #update" do
    before do
      @method = :put
      @action = :update
      @params = {
        facility_id: facility.url_name,
        id: @account.id,
        purchase_order_account: FactoryGirl.attributes_for(:purchase_order_account),
      }
      @params[:purchase_order_account][:affiliate_id] = @params[:purchase_order_account].delete(:affiliate).id
    end

    context "with affiliate" do
      let(:creator) { FactoryGirl.create(:user) }

      before do
        owner = {
          user: creator,
          created_by: creator.id,
          user_role: "Owner",
        }

        account_attrs = {
          created_by: creator.id,
          account_users_attributes: [owner],
        }

        @account = FactoryGirl.create(:purchase_order_account, account_attrs)

        @params[:id] = @account.id
        @params[:account_type] = "PurchaseOrderAccount"
        @params[:purchase_order_account] = @account.attributes

        @params[:purchase_order_account][:affiliate_id] = Affiliate.OTHER.id.to_s
        @params[:purchase_order_account][:affiliate_other] = "Jesus Charisma"
      end

      it_should_allow :director, "to change affiliate to other" do
        expect(assigns(:account)).to eq(@account)
        expect(assigns(:account).affiliate).to be_other
        expect(assigns(:account).affiliate_other).to eq(@params[:purchase_order_account][:affiliate_other])
        is_expected.to set_flash
        assert_redirected_to facility_account_url
      end

      context "not other" do
        before do
          @affiliate = Affiliate.create!(name: "Rod Blagojevich")
          @params[:purchase_order_account][:affiliate_id] = @affiliate.id
        end

        it_should_allow :director do
          expect(assigns(:account)).to eq(@account)
          expect(assigns(:account).affiliate).to eq(@affiliate)
          expect(assigns(:account).affiliate_other).to be_nil
          is_expected.to set_flash
          assert_redirected_to facility_account_url
        end
      end
    end
  end

  describe "GET #new" do
    let(:director) { FactoryGirl.create(:user, :facility_director, facility: facility) }

    before do
      sign_in director
      get :new,
          facility_id: facility.url_name,
          account_type: account_type,
          owner_user_id: account_owner.id
    end

    context "PurchaseOrderAccount" do
      let(:account_type) { "PurchaseOrderAccount" }

      it "loads the account" do
        expect(response).to be_success
        expect(assigns(:account)).to be_a(PurchaseOrderAccount)
      end
    end

    context "CreditCardAccount" do
      let(:account_type) { "CreditCardAccount" }

      it "loads the account" do
        expect(response).to be_success
        expect(assigns(:account)).to be_a(CreditCardAccount)
      end
    end
  end

  context "POST #create" do
    let(:expiration_year) { Time.current.year + 1 }

    before do
      @method = :post
      @action = :create

      @acct_attrs = FactoryGirl.attributes_for(:purchase_order_account)
      @acct_attrs[:affiliate_id] = @acct_attrs.delete(:affiliate).id.to_s

      @acct_attrs.delete :expires_at

      @params = {
        id: @account.id,
        facility_id: facility.url_name,
        owner_user_id: account_owner.id,
        purchase_order_account: @acct_attrs,
        account_type: "PurchaseOrderAccount",
      }

      @params[:purchase_order_account] = @acct_attrs
      allow(@controller).to receive(:current_facility).and_return(facility)
    end

    context "PurchaseOrderAccount" do
      before do
        # December 5
        @acct_attrs[:formatted_expires_at] = "12/5/#{expiration_year}"
      end

      it_should_allow :director do
        expect(assigns(:account).expires_at)
          .to eq(Time.zone.parse("#{expiration_year}-12-05").end_of_day)
        expect(assigns(:account).facility_id).to eq(facility.id)
        expect(assigns(:account)).to be_kind_of PurchaseOrderAccount
        expect(assigns(:account).affiliate)
          .to eq(Affiliate.find(@acct_attrs[:affiliate_id]))
        expect(assigns(:account).affiliate_other).to be_nil
        expect(flash[:notice]).to include("successfully created")
        expect(response)
          .to redirect_to(facility_user_accounts_url(facility, account_owner))
      end
    end

    context "CreditCardAccount" do
      before do
        @params[:account_type] = "CreditCardAccount"
        acct_attrs = FactoryGirl.attributes_for(:credit_card_account)
        acct_attrs[:affiliate_id] = acct_attrs.delete(:affiliate).id.to_s
        acct_attrs[:expiration_month] = "5"
        acct_attrs[:expiration_year] = expiration_year.to_s
        @params[:credit_card_account] = acct_attrs
      end

      it_should_allow :director do
        expect(assigns(:account).expires_at)
          .to eq(Time.zone.parse("#{expiration_year}-5-1").end_of_month.end_of_day)
        expect(assigns(:account).facility.id).to eq(facility.id)
      end
    end
  end
end
