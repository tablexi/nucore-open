require "rails_helper"
require "controller_spec_helper"

RSpec.describe ItemsController do
  let(:item) { @item }
  let(:facility) { @authable }

  render_views

  it "should route" do
    expect(get: "/#{I18n.t('facilities_downcase')}/url_name/items").to route_to(controller: "items", action: "index", facility_id: "url_name")
    expect(get: "/#{I18n.t('facilities_downcase')}/url_name/items/1").to route_to(controller: "items", action: "show", facility_id: "url_name", id: "1")
  end

  before(:all) { create_users }

  before(:each) do
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @item             = @authable.items.create(FactoryGirl.attributes_for(:item, facility_account_id: @facility_account.id))
    @item_pp          = @item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, price_group: @nupg))
    @params = { facility_id: @authable.url_name, id: @item.url_name }
  end

  context "index" do
    before :each do
      @method = :get
      @action = :index
      @params.delete(:id)
    end

    it_should_allow_operators_only do |_user|
      expect(assigns(:products)).to eq([@item])
      expect(response).to be_success
      expect(response).to render_template("admin/products/index")
    end
  end

  context "manage" do
    before :each do
      @method = :get
      @action = :manage
    end

    it_should_allow_operators_only do |_user|
      expect(assigns[:product]).to eq(@item)
      expect(response).to be_success
      expect(response).to render_template("manage")
    end
  end

  context "show" do
    before :each do
      @method = :get
      @action = :show
      @block = proc do
        expect(assigns[:product]).to eq(@item)
        expect(response).to be_success
        expect(response).to render_template("show")
      end
    end

    it "should all public access" do
      do_request
      @block.call
    end

    it_should_allow(:guest) { @block.call }

    it_should_allow_all(facility_operators) { @block.call }

    it "should fail without a valid account" do
      sign_in @guest
      do_request
      expect(flash).not_to be_empty
      expect(assigns[:add_to_cart]).to be false
      expect(assigns[:error]).to eq("no_accounts")
    end

    context "when the item requires approval" do
      before :each do
        add_account_for_user(:guest, item)
        item.update_attributes(requires_approval: true)
      end

      context "if the user is not approved" do
        before(:each) do
          sign_in @guest
          do_request
        end

        context "if the training request feature is enabled", feature_setting: { training_requests: true } do
          it "gives the user the option to submit a request for approval" do
            expect(assigns[:add_to_cart]).to be_blank
            assert_redirected_to(new_facility_product_training_request_path(facility, item))
          end
        end

        context "if the training request feature is disabled", feature_setting: { training_requests: false } do
          it "denies access to the user" do
            expect(assigns[:add_to_cart]).to be_blank
            expect(flash[:notice]).to include("item requires approval")
          end
        end
      end

      it "should not show a notice and show an add to cart" do
        @product_user = ProductUser.create(product: @item, user: @guest, approved_by: @admin.id, approved_at: Time.zone.now)
        add_account_for_user(:guest, @item)
        sign_in @guest
        do_request
        expect(flash).to be_empty
        expect(assigns[:add_to_cart]).to be true
      end

      context "when the user is an admin" do
        before(:each) do
          add_account_for_user(:admin, item)
          sign_in @admin
          do_request
        end

        it "adds the item to the cart" do
          expect(assigns[:add_to_cart]).to be true
        end
      end
    end

    context "hidden item" do
      before :each do
        @item.update_attributes(is_hidden: true)
      end
      it_should_allow_operators_only do
        expect(response).to be_success
      end
      it "should show the page if you're acting as a user" do
        allow_any_instance_of(ItemsController).to receive(:acting_user).and_return(@guest)
        allow_any_instance_of(ItemsController).to receive(:acting_as?).and_return(true)
        sign_in @admin
        do_request
        expect(response).to be_success
        expect(assigns[:product]).to eq(@item)
      end
    end
  end

  context "new" do
    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_managers_only do
      expect(assigns(:product)).to be_kind_of Item
      is_expected.to render_template "new"
    end
  end

  context "edit" do
    before :each do
      @method = :get
      @action = :edit
    end

    it_should_allow_managers_only do
      is_expected.to render_template "edit"
    end
  end

  context "create" do
    before :each do
      @method = :post
      @action = :create
      @params.merge!(item: FactoryGirl.attributes_for(:item, facility_account_id: @facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Item
      is_expected.to set_flash
      assert_redirected_to [:manage, @authable, assigns(:product)]
    end
  end

  context "update" do
    before :each do
      @method = :put
      @action = :update
      @params.merge!(item: FactoryGirl.attributes_for(:item, facility_account_id: @facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Item
      expect(assigns(:product)).to eq(@item)
      is_expected.to set_flash
      assert_redirected_to manage_facility_item_url(@authable, assigns(:product))
    end
  end

  context "destroy" do
    before :each do
      @method = :delete
      @action = :destroy
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Item
      should_be_destroyed @item
      assert_redirected_to facility_items_url
    end
  end
end
