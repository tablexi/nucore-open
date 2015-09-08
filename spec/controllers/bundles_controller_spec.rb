require 'spec_helper'; require 'controller_spec_helper'

describe BundlesController do
  let(:bundle) { @bundle }
  let(:facility) { @authable }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @facility_account=FactoryGirl.create(:facility_account, :facility => @authable)
    @bundle=FactoryGirl.create(:bundle, :facility_account => @facility_account, :facility => @authable)

    # Create at least one item in the bundle, otherwise bundle.can_purchase? will return false
    item = FactoryGirl.create(:item, :facility_account => @facility_account, :facility => @authable)
    price_policy = item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group => @nupg))
    bundle_product = BundleProduct.new(:bundle => @bundle, :product => item, :quantity => 1)
    bundle_product.save!
  end

  context 'index' do
    before(:each) do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      expect(assigns(:archived_product_count)).to be_kind_of Fixnum
      expect(assigns(:not_archived_product_count)).to be_kind_of Fixnum
      expect(assigns(:product_name)).to be_kind_of String
      expect(assigns(:bundles).size).to eq(1)
      expect(assigns(:bundles)).to eq(@authable.bundles.not_archived)
    end

    it 'should show archived facilities' do
      @bundle.is_archived=true
      assert @bundle.save
      maybe_grant_always_sign_in(:director)
      @params.merge!(:archived => 'true')
      do_request
      expect(assigns(:bundles).size).to eq(1)
      expect(assigns(:bundles)).to eq(@authable.bundles.archived)
    end
  end

  context 'show' do
    before(:each) do
      @method=:get
      @action=:show
      @params={ :facility_id => @authable.url_name, :id => @bundle.url_name }
    end

    it 'should flash and falsify @add_to_cart if bundle cannot be purchased' do
      sign_in @guest
      allow_any_instance_of(Bundle).to receive(:available_for_purchase?).and_return(false)
      do_request
      expect(assigns[:add_to_cart]).to be false
      expect(assigns[:error]).to eq('not_available')
      expect(flash[:notice]).not_to be_nil

    end

    it "should fail without a valid account" do
      sign_in @guest
      do_request
      expect(flash).not_to be_empty
      expect(assigns[:add_to_cart]).to be false
      expect(assigns[:error]).to eq('no_accounts')
    end

    it 'should falsify @add_to_cart if #acting_user is nil' do
      allow_any_instance_of(BundlesController).to receive(:acting_user).and_return(nil)
      do_request
      expect(assigns[:add_to_cart]).to be false
      expect(assigns[:login_required]).to be true
    end

    context "when the bundle requires approval" do
      before(:each) do
        add_account_for_user(:guest, bundle.products.first)
        allow_any_instance_of(BundlesController).to receive(:price_policy_available_for_product?).and_return(true)
        bundle.update_attributes(requires_approval: true)
      end

      context "if the user is not approved" do
        before(:each) do
          sign_in @guest
          do_request
        end

        context "if the training request feature is enabled", feature_setting: { training_requests: true } do
          it "gives the user the option to submit a request for approval" do
            expect(assigns[:add_to_cart]).to be_blank
            assert_redirected_to(new_facility_product_training_request_path(facility, bundle))
          end
        end

        context "if the training request feature is disabled", feature_setting: { training_requests: false } do
          it "denies access to the user" do
            expect(assigns[:add_to_cart]).to be_blank
            expect(flash[:notice]).to include("bundle requires approval")
          end
        end
      end
    end

    it 'should flash and falsify @add_to_cart if there is no price group for user to purchase through' do
      add_account_for_user(:guest, @bundle.products.first, @nupg)
      sign_in @guest
      allow_any_instance_of(BundlesController).to receive(:price_policy_available_for_product?).and_return(false)
      do_request
      expect(assigns[:add_to_cart]).to be false
      expect(assigns[:error]).to eq('not_in_price_group')
      expect(flash[:notice]).not_to be_nil
    end

    it 'should flash and falsify @add_to_cart if user is not authorized to purchase on behalf of another user' do
      sign_in @guest
      switch_to @staff

      do_request
      expect(assigns[:add_to_cart]).to be false
      expect(assigns[:error]).to eq('not_authorized_acting_as')
    end

    it 'should not require login' do
      do_request
      assert_init_bundle
      expect(assigns(:add_to_cart)).to_not be_nil
      expect(assigns(:login_required)).to_not be_nil
      is_expected.not_to set_the_flash
      is_expected.to render_template('show')
    end

    context "restricted bundle" do
      before :each do
        @bundle.update_attributes(:requires_approval => true)
        allow_any_instance_of(BundlesController).to receive(:price_policy_available_for_product?).and_return(true)
      end
      it "should show a notice if you're not approved" do
        sign_in @guest
        do_request
        expect(assigns[:add_to_cart]).to be false
        expect(flash[:notice]).not_to be_nil
      end

      it "should not show a notice and show an add to cart" do
        @product_user = ProductUser.create(:product => @bundle, :user => @guest, :approved_by => @admin.id, :approved_at => Time.zone.now)
        add_account_for_user(:guest, @bundle.products.first, @nupg)
        sign_in @guest
        do_request
        expect(flash).to be_empty
        expect(assigns[:add_to_cart]).to be true
      end

      context "when the user is an admin" do
        before(:each) do
          add_account_for_user(:admin, bundle.products.first)
          sign_in @admin
          do_request
        end

        it "adds the bundle to the cart" do
          expect(assigns[:add_to_cart]).to be true
        end
      end
    end
  end

  context 'new' do
    before(:each) do
      @method=:get
      @action=:new
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_allow_managers_only do
      expect(assigns(:bundle)).to be_kind_of Bundle
      expect(assigns(:bundle)).to be_new_record
      is_expected.to render_template('new')
    end
  end

  context 'edit' do
    before(:each) do
      @method=:get
      @action=:edit
      @params={ :facility_id => @authable.url_name, :id => @bundle.url_name }
    end

    it_should_require_login

    it_should_allow_managers_only do
      assert_init_bundle
      is_expected.to render_template('edit')
    end
  end

  context 'create' do
    before(:each) do
      @method = :post
      @action = :create
      @params = { :facility_id => @authable.url_name, :bundle => FactoryGirl.attributes_for(:bundle) }
    end

    it_should_require_login

    it_should_allow_managers_only :redirect do
      expect(assigns(:bundle)).to be_kind_of Bundle
      expect(assigns(:bundle).initial_order_status_id).to eq(OrderStatus.default_order_status.id)
      expect(assigns(:bundle).requires_approval).to eq(false)
      expect(assigns(:bundle)).to be_persisted
      is_expected.to set_the_flash
      assert_redirected_to [ :manage, @authable, assigns(:bundle) ]
    end
  end

  context 'update' do
    before(:each) do
      @method=:put
      @action=:update
      @params={
        :facility_id => @authable.url_name,
        :id => @bundle.url_name,
        :bundle => FactoryGirl.attributes_for(:bundle, :url_name => @bundle.url_name)
      }
    end

    it_should_require_login

    it_should_allow_managers_only :redirect do
      assert_init_bundle
      is_expected.to set_the_flash
      assert_redirected_to manage_facility_bundle_url(@authable, @bundle)
    end
  end

  def assert_init_bundle
    expect(assigns(:bundle)).to_not be_nil
    expect(assigns(:bundle)).to eq(@bundle)
  end
end

