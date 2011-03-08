require 'spec_helper'; require 'controller_spec_helper'

describe BundlesController do
  integrate_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @bundle=Factory.create(:bundle, :facility_account => @facility_account, :facility => @authable)
  end


  context 'index' do

    before(:each) do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      should assign_to(:archived_product_count).with_kind_of(Fixnum)
      should assign_to(:not_archived_product_count).with_kind_of(Fixnum)
      should assign_to(:product_name).with_kind_of(String)
      should assign_to(:bundles).with_kind_of(Array)
      assigns(:bundles).size.should == 1
      assigns(:bundles).should == @authable.bundles.not_archived
    end

    it 'should show archived facilities' do
      @bundle.is_archived=true
      assert @bundle.save
      maybe_grant_always_sign_in(:director)
      do_request @params.merge(:archived => 'true')
      should assign_to(:bundles).with_kind_of(Array)
      assigns(:bundles).size.should == 1
      assigns(:bundles).should == @authable.bundles.archived
    end

  end


  context 'show' do

    before(:each) do
      @method=:get
      @action=:show
      @params={ :facility_id => @authable.url_name, :id => @bundle.url_name }
    end

    it 'should flash and falsify @add_to_cart if bundle cannot be purchased'
    it 'should falsify @add_to_cart if #acting_user is nil'
    it 'should flash and falsify @add_to_cart if user is not approved'
    it 'should flash and falsify @add_to_cart if there is no price group for user to purchase through'
    it 'should flash and falsify @add_to_cart if user is not authorized to purchase on behalf of another user'

    it 'should not require login' do
      do_request
      assert_init_bundle
      should assign_to(:add_to_cart)
      should assign_to(:log_in)
      should_not set_the_flash
      should render_template('show.html.haml')
    end

  end


  context 'new' do

    before(:each) do
      @method=:get
      @action=:new
      @params={ :facility_id => @authable.url_name }
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      should assign_to(:bundle).with_kind_of(Bundle)
      assigns(:bundle).should be_new_record
      should render_template('new.html.haml')
    end

  end


  context 'edit' do

    before(:each) do
      @method=:get
      @action=:edit
      @params={ :facility_id => @authable.url_name, :id => @bundle.url_name }
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      assert_init_bundle
      should render_template('edit.html.haml')
    end

  end


  context 'create' do

    before(:each) do
      @method=:post
      @action=:create
      @params={ :facility_id => @authable.url_name, :bundle => Factory.attributes_for(:bundle) }
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      should assign_to(:bundle).with_kind_of(Bundle)
      assigns(:bundle).initial_order_status_id.should == OrderStatus.default_order_status.id
      assigns(:bundle).requires_approval.should == false
      should set_the_flash
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
        :bundle => Factory.attributes_for(:bundle, :url_name => @bundle.url_name)
      }
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      assert_init_bundle
      should set_the_flash
      assert_redirected_to manage_facility_bundle_url(@authable, @bundle)
    end

  end


  def assert_init_bundle
    should assign_to(:bundle)
    assigns(:bundle).should == @bundle
  end
end