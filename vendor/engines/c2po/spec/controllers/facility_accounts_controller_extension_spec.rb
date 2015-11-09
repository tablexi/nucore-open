require "rails_helper"
require 'controller_spec_helper'

RSpec.describe FacilityAccountsController do
  render_views

  let(:account) { @account }
  let(:facility) { FactoryGirl.create(:facility) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility # TODO replace '@authable' with 'facility' throughout
    @facility_account=FactoryGirl.create(:facility_account, :facility => @authable)
    @item=FactoryGirl.create(:item, :facility_account => @facility_account, :facility => @authable)
    @account=FactoryGirl.create(:credit_card_account, :account_users_attributes => [ FactoryGirl.attributes_for(:account_user, :user => @owner) ])
    grant_role(@purchaser, @account)
    grant_role(@owner, @account)
    @order=FactoryGirl.create(:order, :user => @purchaser, :created_by => @purchaser.id, :facility => @authable)
    @order_detail=FactoryGirl.create(:order_detail, :product => @item, :order => @order, :account => @account)
  end


  context 'update' do

    before(:each) do
      @method=:put
      @action=:update
      @params={
        :facility_id => @authable.url_name,
        :id => @account.id,
        :account => FactoryGirl.attributes_for(:purchase_order_account)
      }
      @params[:account][:affiliate_id] = @params[:account].delete(:affiliate).id
    end


    context 'with affiliate' do

      before :each do
        user=FactoryGirl.create(:user)

        owner={
          :user => user,
          :created_by => user.id,
          :user_role => 'Owner'
        }

        account_attrs={
          :created_by => user.id,
          :account_users_attributes => [owner],
        }

        @account=FactoryGirl.create(:purchase_order_account, account_attrs)

        @params[:id] = @account.id
        @params[:class_type] = 'PurchaseOrderAccount'
        @params[:account] = @account.attributes

        @params[:account][:affiliate_id] = Affiliate.OTHER.id.to_s
        @params[:account][:affiliate_other] ='Jesus Charisma'
      end

      it_should_allow :director, 'to change affiliate to other' do
        expect(assigns(:account)).to eq(@account)
        expect(assigns(:account).affiliate).to eq(Affiliate.OTHER)
        expect(assigns(:account).affiliate_other).to eq(@params[:account][:affiliate_other])
        is_expected.to set_flash
        assert_redirected_to facility_account_url
      end

      context 'not other' do

        before :each do
          @affiliate=Affiliate.create!(:name => 'Rod Blagojevich')
          @params[:account][:affiliate_id] = @affiliate.id
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


  context 'create' do
    before :each do
      @method = :post
      @action = :create

      @expiration_year        = Time.zone.now.year+1
      @acct_attrs             = FactoryGirl.attributes_for(:purchase_order_account)
      @acct_attrs[:affiliate_id] = @acct_attrs.delete(:affiliate).id.to_s

      @acct_attrs.delete :expires_at

      @params = {
        :id            => @account.id,
        :facility_id   => @authable.url_name,
        :owner_user_id => @owner.id,
        :account       => @acct_attrs,
        :class_type    => 'PurchaseOrderAccount'
      }

      @params[:account] = @acct_attrs
      allow(@controller).to receive(:current_facility).and_return(@authable)
    end

    context 'PurchaseOrderAccount' do
      before :each do
        @acct_attrs[:expires_at] = "12/5/#{@expiration_year}"
      end

      it_should_allow :director do
        expect(assigns(:account).expires_at).to eq(Time.zone.parse("#{@expiration_year}-5-12").end_of_day)
        expect(assigns(:account).facility_id).to eq(@authable.id)
        expect(assigns(:account)).to be_kind_of PurchaseOrderAccount
        expect(assigns(:account).affiliate).to eq(Affiliate.find(@acct_attrs[:affiliate_id]))
        expect(assigns(:account).affiliate_other).to be_nil
        is_expected.to set_flash
        expect(response).to redirect_to(facility_user_accounts_url(facility, @owner))
      end
    end

    context 'CreditCardAccount' do
      before :each do
        @params[:class_type]           = 'CreditCardAccount'
        @acct_attrs                    = FactoryGirl.attributes_for(:credit_card_account)
        @acct_attrs[:affiliate_id]     = @acct_attrs.delete(:affiliate).id.to_s
        @acct_attrs[:expiration_month] = "5"
        @acct_attrs[:expiration_year]  = @expiration_year.to_s
        @params[:account]              = @acct_attrs
      end

      it_should_allow :director do
        expect(assigns(:account).expires_at).to  eq(Time.zone.parse("#{@expiration_year}-5-1").end_of_month.end_of_day)
        expect(assigns(:account).facility.id).to eq(@authable.id)
      end
    end
  end

  shared_examples 'an authable account' do
    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    context 'the selected_account param is set' do
      context 'selected_account is valid' do
        before :each do
          @params[:selected_account] = unreconciled_account.id
        end

        it_should_allow_all facility_managers do
          is_expected.to render_template 'c2po/reconcile'
        end
      end

      context 'selected_account is invalid' do
        before :each do
          @params[:selected_account] = account.id
        end

        it_should_allow_all facility_managers do
          is_expected.to redirect_to redirect_path
        end
      end
    end

    context 'the selected_account param is not set' do
      it_should_allow_all facility_managers do
        expect(assigns :subnav).to eq('billing_nav')
        expect(assigns :active_tab).to eq('admin_billing')
        expect(assigns :accounts).to be_kind_of ActiveRecord::Relation
        expect(assigns :selected).to eq assigns(:accounts).first
        expect(assigns(:unreconciled_details).to_a)
          .to eq OrderDetail.account_unreconciled(facility, assigns(:selected)).to_a
        is_expected.to render_template('c2po/reconcile')
      end
    end
  end

  context 'credit_cards with account' do
    let(:unreconciled_account) { build(:credit_card_account) }
    let(:redirect_path) { credit_cards_facility_accounts_path }

    before :each do
      prepare_for_account_show(:credit_cards, unreconciled_account)
    end

    it_behaves_like 'an authable account'
  end


  context 'credit_cards without account' do

    before :each do
      @method=:get
      @action=:credit_cards
      @params={ :facility_id => @authable.url_name }
    end

    it_should_allow :director do
      expect(assigns(:subnav)).to eq('billing_nav')
      expect(assigns(:active_tab)).to eq('admin_billing')
      expect(assigns(:accounts)).to be_empty
      expect(assigns(:selected)).to be_nil
      expect(assigns(:unreconciled_details)).to be_nil
      is_expected.to render_template('c2po/reconcile')
    end

  end


  context 'purchase_orders with account' do
    let(:unreconciled_account) { build(:purchase_order_account) }
    let(:redirect_path) { purchase_orders_facility_accounts_path }

    before :each do
      prepare_for_account_show(:purchase_orders, unreconciled_account)
    end

    it_behaves_like 'an authable account'
  end


  context 'purchase_orders without account' do

    before :each do
      @method=:get
      @action=:purchase_orders
      @params={ :facility_id => @authable.url_name }
    end

    it_should_allow :director do
      expect(assigns(:subnav)).to eq('billing_nav')
      expect(assigns(:active_tab)).to eq('admin_billing')
      expect(assigns(:accounts)).to be_empty
      expect(assigns(:selected)).to be_nil
      expect(assigns(:unreconciled_details)).to be_nil
      is_expected.to render_template('c2po/reconcile')
    end

  end


  context 'update_credit_cards' do

    before :each do
      ccact=FactoryGirl.build(:credit_card_account)
      prepare_for_account_update(:update_credit_cards, ccact)
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      expect(assigns(:error_fields)).to be_empty
      is_expected.to set_flash
      assert_redirected_to credit_cards_facility_accounts_path
      @order_detail.reload
      expect(@order_detail.state).to eq('reconciled')
      expect(@order_detail.reconciled_note).not_to be_nil
    end

    it 'should test multiple cards sent in one POST'
    it 'should test transaction failure'

  end


  context 'update_purchase_orders' do

    before :each do
      @poact=FactoryGirl.build(:purchase_order_account)
      prepare_for_account_update(:update_purchase_orders, @poact)
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do |user|
      expect(assigns(:error_fields)).to be_empty
      is_expected.to set_flash
      assert_redirected_to purchase_orders_facility_accounts_path
      @order_detail.reload
      expect(@order_detail.state).to eq('reconciled')
      expect(@order_detail.reconciled_note).not_to be_nil
    end

    it 'should test multiple purchase orders sent in one POST'
    it 'should test transaction failure'

  end



  private

  def prepare_for_account_update(action, account)
    @method=:post
    @action=action
    account.account_users_attributes = [{:user_id => @purchaser.id, :user_role => AccountUser::ACCOUNT_OWNER, :created_by => @admin.id }]
    assert account.save
    @price_policy=FactoryGirl.create(:item_price_policy, :product => @item, :price_group => @nupg)
    @price_group_product=FactoryGirl.create(:price_group_product, :product => @item, :price_group => @nupg, :reservation_window => nil)
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
    statement=FactoryGirl.create(:statement, :facility_id => @authable.id, :created_by => @admin.id, :account => account)
    @order_detail.to_complete!
    @order_detail.update_attributes(account: account, fulfilled_at: 1.day.ago, actual_cost: 10, actual_subsidy: 2)
    @order_detail.statement = statement
    @order_detail.save
  end

end
