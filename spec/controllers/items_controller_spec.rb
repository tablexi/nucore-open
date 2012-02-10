require 'spec_helper'; require 'controller_spec_helper'

describe ItemsController do
  render_views

  it "should route" do
    { :get => "/facilities/url_name/items" }.should route_to(:controller => 'items', :action => 'index', :facility_id => 'url_name')
    { :get => "/facilities/url_name/items/1" }.should route_to(:controller => 'items', :action => 'show', :facility_id => 'url_name', :id => "1")
  end

  before(:all) { create_users }

  before(:each) do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @item             = @authable.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
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
        sign_in @guest
        do_request
        flash.should be_empty
        assigns[:add_to_cart].should be_true
      end
      
      it "should allow an admin to allow it to add to cart" do
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
      it "should throw a 404 if you're not an admin" do
        sign_in @guest
        do_request
        response.should_not be_success
        response.response_code.should == 404
      end
      it "should show the page if you're an admin" do
        sign_in @admin
        do_request
        response.should be_success
        assigns[:item].should == @item
      end
      it "should show the page if you're acting as a user" do
        ItemsController.any_instance.stubs(:acting_user).returns(@guest)
        ItemsController.any_instance.stubs(:acting_as?).returns(true)
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

    it_should_allow_operators_only do
      should assign_to(:item).with_kind_of Item
      should render_template 'new'
    end

  end


  context "edit" do

    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_operators_only do
      should render_template 'edit'
    end

  end


  context "create" do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(:item => Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    end

    it_should_allow_operators_only :redirect do
      should assign_to(:item).with_kind_of Item
      should set_the_flash
      assert_redirected_to [:manage, @authable, assigns(:item)]
    end

  end


  context "update" do

    before :each do
      @method=:put
      @action=:update
      @params.merge!(:item => Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    end

    it_should_allow_operators_only :redirect do
      should assign_to(:item).with_kind_of Item
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

    it_should_allow_operators_only :redirect do
      should assign_to(:item).with_kind_of Item
      should_be_destroyed @item
      assert_redirected_to facility_items_url
    end

  end

end
