require 'spec_helper'; require 'controller_spec_helper'

describe ItemsController do
  render_views

  it "should route" do
    { :get => "/facilities/url_name/items" }.should route_to(:controller => 'items', :action => 'index', :facility_id => 'url_name')
    { :get => "/facilities/url_name/items/1" }.should route_to(:controller => 'items', :action => 'show', :facility_id => 'url_name', :id => "1")
  end

  before(:all) { create_users }

  before(:each) do
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @item             = @authable.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    @item_pp          = @item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group => @nupg))
    @params={ :facility_id => @authable.url_name, :id => @item.url_name }
  end


  context "index" do

    before :each do
      @method=:get
      @action=:index
      @params.delete(:id)
    end

    it_should_allow_operators_only do |user|
      assigns[:items].should == [@item]
      response.should be_success
      response.should render_template('items/index')
    end

  end


  context "manage" do

    before :each do
      @method=:get
      @action=:manage
    end

    it_should_allow_operators_only do |user|
      assigns[:item].should == @item
      response.should be_success
      response.should render_template('items/manage')
    end

  end


  context "show" do

    before :each do
      @method=:get
      @action=:show
      @block=Proc.new do
        assigns[:item].should == @item
        response.should be_success
        response.should render_template('items/show')
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
      flash.should_not be_empty
      assigns[:add_to_cart].should be_false
      assigns[:error].should == 'no_accounts'
    end

    context "restricted item" do
      before :each do
        @item.update_attributes(:requires_approval => true)
      end
      it "should show a notice if you're not approved" do
        sign_in @guest
        do_request
        assigns[:add_to_cart].should be_false
        flash[:notice].should_not be_nil
      end

      it "should not show a notice and show an add to cart" do
        @product_user = ProductUser.create(:product => @item, :user => @guest, :approved_by => @admin.id, :approved_at => Time.zone.now)
        nufs=create_nufs_account_with_owner :guest
        define_open_account @item.account, nufs.account_number
        sign_in @guest
        do_request
        flash.should be_empty
        assigns[:add_to_cart].should be_true
      end

      it "should allow an admin to allow it to add to cart" do
        nufs=create_nufs_account_with_owner :admin
        define_open_account @item.account, nufs.account_number
        sign_in @admin
        do_request
        flash.should_not be_empty
        assigns[:add_to_cart].should be_true
      end
    end

    context "hidden item" do
      before :each do
        @item.update_attributes(:is_hidden => true)
      end
      it_should_allow_operators_only do
        response.should be_success
      end
      it "should show the page if you're acting as a user" do
        ItemsController.any_instance.stub(:acting_user).and_return(@guest)
        ItemsController.any_instance.stub(:acting_as?).and_return(true)
        sign_in @admin
        do_request
        response.should be_success
        assigns[:item].should == @item
      end
    end

  end


  context "new" do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_managers_only do
      expect(assigns(:item)).to be_kind_of Item
      should render_template 'new'
    end

  end


  context "edit" do

    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_managers_only do
      should render_template 'edit'
    end

  end


  context "create" do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(:item => FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:item)).to be_kind_of Item
      should set_the_flash
      assert_redirected_to [:manage, @authable, assigns(:item)]
    end

  end


  context "update" do

    before :each do
      @method=:put
      @action=:update
      @params.merge!(:item => FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:item)).to be_kind_of Item
      assigns(:item).should == @item
      should set_the_flash
      assert_redirected_to manage_facility_item_url(@authable, assigns(:item))
    end

  end


  context "destroy" do

    before :each do
      @method=:delete
      @action=:destroy
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:item)).to be_kind_of Item
      should_be_destroyed @item
      assert_redirected_to facility_items_url
    end

  end

end
