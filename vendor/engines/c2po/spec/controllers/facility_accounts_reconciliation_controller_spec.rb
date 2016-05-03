require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityAccountsReconciliationController do
  render_views

  let(:account) { @account }
  let(:facility) { FactoryGirl.create(:facility) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility # TODO: replace '@authable' with 'facility' throughout
    @facility_account = FactoryGirl.create(:facility_account, facility: @authable)
    @item = FactoryGirl.create(:item, facility_account: @facility_account, facility: @authable)
    @account = FactoryGirl.create(:credit_card_account, account_users_attributes: [FactoryGirl.attributes_for(:account_user, user: @owner)])
    grant_role(@purchaser, @account)
    grant_role(@owner, @account)
    @order = FactoryGirl.create(:order, user: @purchaser, created_by: @purchaser.id, facility: @authable)
    @order_detail = FactoryGirl.create(:order_detail, product: @item, order: @order, account: @account)
  end

  shared_examples "an authable account" do
    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    context "the selected_account param is set" do
      context "selected_account is valid" do
        before :each do
          @params[:selected_account] = unreconciled_account.id
        end

        it_should_allow_all facility_managers do
          is_expected.to render_template "facility_accounts_reconciliation/index"
        end
      end

      context "selected_account is invalid" do
        before :each do
          @params[:selected_account] = account.id
        end

        it_should_allow_all facility_managers do
          is_expected.to redirect_to redirect_path
        end
      end
    end

    context "the selected_account param is not set" do
      it_should_allow_all facility_managers do
        expect(assigns(:subnav)).to eq("billing_nav")
        expect(assigns(:active_tab)).to eq("admin_billing")
        expect(assigns(:accounts)).to be_kind_of ActiveRecord::Relation
        expect(assigns(:selected_account)).to eq assigns(:accounts).first
        expect(assigns(:unreconciled_details).to_a)
          .to eq OrderDetail.account_unreconciled(facility, assigns(:selected_account)).to_a
        is_expected.to render_template("facility_accounts_reconciliation/index")
      end
    end
  end

  context "credit_cards with account" do
    let(:unreconciled_account) { build(:credit_card_account) }
    let(:redirect_path) { credit_cards_facility_accounts_path }

    before :each do
      prepare_for_account_show("CreditCardAccount", unreconciled_account)
    end

    it_behaves_like "an authable account"
  end

  context "credit_cards without account" do
    before :each do
      @method = :get
      @action = :index
      @params = { facility_id: @authable.url_name, account_type: "CreditCardAccount" }
    end

    it_should_allow :director do
      expect(assigns(:subnav)).to eq("billing_nav")
      expect(assigns(:active_tab)).to eq("admin_billing")
      expect(assigns(:accounts)).to be_empty
      expect(assigns(:selected)).to be_nil
      expect(assigns(:unreconciled_details)).to be_nil
      expect(response).to render_template("facility_accounts_reconciliation/index")
    end
  end

  context "purchase_orders with account" do
    let(:unreconciled_account) { build(:purchase_order_account) }
    let(:redirect_path) { purchase_orders_facility_accounts_path }

    before :each do
      prepare_for_account_show("PurchaseOrderAccount", unreconciled_account)
    end

    it_behaves_like "an authable account"
  end

  context "purchase_orders without account" do
    before :each do
      @method = :get
      @action = :index
      @params = { facility_id: @authable.url_name, account_type: "PurchaseOrderAccount" }
    end

    it_should_allow :director do
      expect(assigns(:subnav)).to eq("billing_nav")
      expect(assigns(:active_tab)).to eq("admin_billing")
      expect(assigns(:accounts)).to be_empty
      expect(assigns(:selected)).to be_nil
      expect(assigns(:unreconciled_details)).to be_nil
      expect(response).to render_template("facility_accounts_reconciliation/index")
    end
  end

  context "update_credit_cards" do
    before :each do
      ccact = FactoryGirl.build(:credit_card_account)
      prepare_for_account_update("CreditCardAccount", ccact)
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      expect(flash.now[:error]).to be_blank
      is_expected.to set_flash
      assert_redirected_to credit_cards_facility_accounts_path
      @order_detail.reload
      expect(@order_detail.state).to eq("reconciled")
      expect(@order_detail.reconciled_note).not_to be_nil
    end

    describe "errors" do
      describe "an exception" do
        before do
          allow_any_instance_of(OrderDetail).to receive(:change_status!).and_raise("Some error")
        end

        it_should_allow :admin do
          expect(flash.now[:error]).to include("Some error")
        end
      end
    end
  end

  context "update_purchase_orders" do
    before :each do
      @poact = FactoryGirl.build(:purchase_order_account)
      prepare_for_account_update("PurchaseOrderAccount", @poact)
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do |_user|
      expect(flash.now[:error]).to be_blank
      is_expected.to set_flash
      assert_redirected_to purchase_orders_facility_accounts_path
      @order_detail.reload
      expect(@order_detail.state).to eq("reconciled")
      expect(@order_detail.reconciled_note).not_to be_nil
    end
  end

  private

  def prepare_for_account_update(account_type, account)
    @method = :post
    @action = :update
    account.account_users_attributes = [{ user_id: @purchaser.id, user_role: AccountUser::ACCOUNT_OWNER, created_by: @admin.id }]
    account.save!
    @price_policy = FactoryGirl.create(:item_price_policy, product: @item, price_group: @nupg)
    @price_group_product = FactoryGirl.create(:price_group_product, product: @item, price_group: @nupg, reservation_window: nil)
    @order_detail.account = account
    @order_detail.assign_price_policy
    @order_detail.save!

    @order_detail.change_status!(OrderStatus.complete.first)

    statement = FactoryGirl.create(:statement, facility_id: @authable.id, created_by: @admin.id, account: account)
    @order_detail.update_attributes!(account: account, fulfilled_at: 1.day.ago, actual_cost: 10, actual_subsidy: 2)
    @order_detail.statement = statement
    @order_detail.save!

    @params = {
      facility_id: @authable.url_name,
      account_type: account_type,
      selected_account: account.id,
      order_detail: {
        @order_detail.id.to_s => {
          reconciled: "1",
          reconciled_note: "this transaction is fake",
        },
      },
    }
  end

  def prepare_for_account_show(account_type, account)
    @method = :get
    @action = :index
    @params = { facility_id: @authable.url_name, account_type: account_type }
    account.account_users_attributes = [{ user_id: @purchaser.id, user_role: AccountUser::ACCOUNT_OWNER, created_by: @admin.id }]
    assert account.save
    statement = FactoryGirl.create(:statement, facility_id: @authable.id, created_by: @admin.id, account: account)
    @order_detail.to_complete!
    @order_detail.update_attributes(account: account, fulfilled_at: 1.day.ago, actual_cost: 10, actual_subsidy: 2)
    @order_detail.statement = statement
    @order_detail.save
  end
end
