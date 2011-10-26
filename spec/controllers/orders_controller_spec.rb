require 'spec_helper'; require 'controller_spec_helper'

describe OrdersController do
  render_views

  before(:all) { create_users }


  it "should route" do
    { :get => "/orders/cart" }.should route_to(:controller => "orders", :action => "cart")
    { :get => "/orders/1" }.should route_to(:controller => "orders", :action => "show", :id => "1")
    { :put => "/orders/1" }.should route_to(:controller => "orders", :action => "update", :id => "1")
    { :put => "/orders/1/add" }.should route_to(:controller => "orders", :action => "add", :id => "1")
    { :put => "/orders/1/remove/3" }.should route_to(:controller => "orders", :action => "remove", :id => "1", :order_detail_id => "3")
    { :put => "/orders/1" }.should route_to(:controller => "orders", :action => "update", :id => "1")
    { :put => "/orders/1/clear" }.should route_to(:controller => "orders", :action => "clear", :id => "1")
    { :put => "/orders/1/purchase" }.should route_to(:controller => "orders", :action => "purchase", :id => "1")
    { :get => "/orders/1/receipt" }.should route_to(:controller => "orders", :action => "receipt", :id => "1")
    { :get => "/orders/1/choose_account" }.should route_to(:controller => "orders", :action => "choose_account", :id => "1")
  end

  before :each do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @price_group      = @authable.price_groups.create(Factory.attributes_for(:price_group))
    @account          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @staff, :created_by => @staff, :user_role => AccountUser::ACCOUNT_OWNER]])
    @order            = @staff.orders.create(Factory.attributes_for(:order, :created_by => @staff.id, :account => @account))
    @item             = @authable.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    @params={ :id => @order.id }
  end


  context 'cart' do

    before :each do
      @method=:get
      @action=:cart
    end

    it_should_require_login

    it_should_allow :staff do
      assert_redirected_to order_path(@order)
    end

    it 'should test more than auth'
  end


  context 'choose_account' do

    before :each do
      @order.add(@item, 1)
      @order.order_details.size.should == 1

      @method=:get
      @action=:choose_account
      @params.merge!(:account_id => @account.id)
    end

    it_should_require_login

    it_should_allow :staff do
      should assign_to(:order).with_kind_of Order
      assigns(:order).should == @order
      should render_template 'choose_account'
    end

    it 'should test more than auth'
  end


  context 'purchase' do

    before :each do
      @method=:put
      @action=:purchase
    end

    it_should_require_login

    it_should_allow :staff do
      should assign_to(:order).with_kind_of Order
      assigns(:order).should == @order
      should respond_with :redirect
    end

    it 'should test more than auth'

  end


  context 'receipt' do

    before :each do
      @order.state='purchased'
      assert @order.save

      @method=:get
      @action=:receipt
    end

    it_should_require_login

    it_should_allow :staff do
      should assign_to(:order).with_kind_of Order
      assigns(:order).should == @order
      should render_template 'receipt'
    end

  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_require_login

    it_should_allow :staff do
      should assign_to(:order_details).with_kind_of Array
      should render_template 'index'
    end

  end


  context "add to cart" do
    before(:each) do
      @method=:put
      @action=:add
      @params.merge!(:quantity => 1, :product_id => @item.id)
    end

    it_should_require_login

    it_should_allow :staff, "to add a product with quantity to cart" do
      do_request
      assigns(:order).should == @order
      assigns(:product).should == @item
      @order.reload.order_details.size.should == 1
      flash[:error].should be_nil
      should set_the_flash
      response.should redirect_to "/orders/#{@order.id}"
    end

    context 'as instrument' do
      before :each do
        @options=Factory.attributes_for(:instrument, :facility_account => @facility_account,
                                        :min_reserve_mins => 60, :max_reserve_mins => 60, :relay_ip => '192.168.1.1')
        @instrument=@authable.instruments.create(@options)
        @order2=@staff.orders.create(Factory.attributes_for(:order, :created_by => @staff.id, :account => @account))
        @params[:id]=@order2.id
        @params[:product_id]=@instrument.id
      end

      it_should_allow :staff do
        assigns(:order).should == @order2
        assigns(:product).should == @instrument
        @order2.reload.order_details.size.should == 1
        flash[:error].should be_nil
        assert_redirected_to new_order_order_detail_reservation_path(@order2, @order2.order_details.first)
      end
    end

    context "no account" do
      it "should redirect to choose_account when /add/:product_id/:quantity is called and cart doesn't have an account" do
        @order.account = nil
        @order.save
        maybe_grant_always_sign_in :staff
        do_request
        response.should redirect_to("/orders/#{@order.id}/choose_account")
      end

      context "mixed facility" do
        it "should flash error message containing another" do
          @facility2          = Factory.create(:facility)
          @facility_account2  = @facility2.facility_accounts.create!(Factory.attributes_for(:facility_account))
          @account2           = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @staff, :created_by => @staff, :user_role => AccountUser::ACCOUNT_OWNER]])
          @item2              = @facility2.items.create!(Factory.attributes_for(:item, :facility_account_id => @facility_account2.id))
          # add first item to cart 
          maybe_grant_always_sign_in :staff
          do_request

          # add second item to cart
          @params[:product_id]=@item2.id
          do_request

          should set_the_flash.to(/can not/)
          should set_the_flash.to(/another/)
          response.should redirect_to "/orders/#{@order.id}"  
        end
      end
    end

    it "should show a warning if the user doesn't have access to the product to be added"
  end


  context "remove from cart" do
    before(:each) do
      @order.add(@item, 1)
      @order.order_details.size.should == 1
      @order_detail = @order.order_details[0]

      @method=:put
      @action=:remove
      @params.merge!(:order_detail_id => @order_detail.id)
    end

    it_should_require_login

    it_should_allow :staff, "should delete an order_detail when /remove/:order_detail_id is called" do
      @order.reload.order_details.size.should == 0
      response.should redirect_to "/orders/#{@order.id}"
    end

    it "should 404 it the order_detail to be removed is not in the current cart" do
      @account2 = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @director, :created_by => @director, :user_role => 'Owner']])
      @order2   = @director.orders.create(Factory.attributes_for(:order, :user => @director, :created_by => @director, :account => @account2))
      @order2.add(@item)
      @order_detail2 = @order2.order_details[0]
      @params[:order_detail_id]=@order_detail2.id
      maybe_grant_always_sign_in :staff
      do_request
      response.response_code.should == 404
    end

    context "removing last item in cart" do
      it "should nil out the payment source in the order/session" do
        maybe_grant_always_sign_in :staff
        do_request

        response.should redirect_to "/orders/#{@order.id}"
        should set_the_flash.to /removed/

        @order.reload.order_details.size.should == 0
        @order.reload.account.should == nil
      end
    end
  end


  context "update order_detail quantities" do
    before(:each) do
      @item_pp   = Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      @pg_member = Factory.create(:user_price_group_member, :user => @staff, :price_group => @price_group)
      @staff.cart.add(@item,1)
      @order_detail = @order.reload.order_details[0]
      @order_detail.quantity.should == 1
      @method=:put
      @action=:update
      @params.merge!("quantity#{@order_detail.id}" => "6")
    end

    it_should_require_login

    it_should_allow :staff, "to update the quantities of order_details" do
      @order_detail.reload.quantity.should == 6
    end

    it "should not allow updates of quantities for instruments"
  end


  context "cart meta data" do
    before(:each) do
      @instrument       = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @service          = @authable.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
      @method=:get
      @action=:show
    end

    it_should_require_login

    context 'staff' do

      before :each do
        @order.add(@instrument)
        @order_detail = @order.order_details.first
      end

      it_should_allow :staff, "to show links for making a reservation for instruments" do
        response.should be_success
      end
    end

    it "should show links for uploading files for services where required by service"
    it "should show links for submitting survey for services where required by service"
  end


  context "clear" do
    before(:each) do
      @method=:put
      @action=:clear
    end

    it_should_require_login

    it_should_allow :staff, "to clear the cart and redirect back to cart" do
      @order.order_details.size == 0
      assert_redirected_to order_path(@order)
    end

  end


  context "checkout" do
    before(:each) do
      @item_pp          = Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      @pg_member        = Factory.create(:user_price_group_member, :user => @staff, :price_group => @price_group)
      @order.add(@item, 10)
      @method=:get
      @action=:show
    end

    it_should_require_login

    it "should disallow viewing of cart that is purchased" do
      Factory.create(:price_group_product, :product => @item, :price_group =>@price_group, :reservation_window => nil)
      define_open_account(@item.account, @account.account_number)
      @order.validate_order!
      @order.purchase!
      maybe_grant_always_sign_in :staff
      do_request
      response.should redirect_to "/orders/#{@order.id}/receipt"

      @action=:choose_account
      do_request
      response.should redirect_to "/orders/#{@order.id}/receipt"

      @method=:put
      @action=:purchase
      do_request
      response.should redirect_to "/orders/#{@order.id}/receipt"

      # TODO: add, etc.
    end

    it "should validate and transition to validated"

    it "should only allow checkout if the cart has at least one order_detail"
  end

  context "receipt /receipt/:order_id" do
    it "should 404 unless :order_id exists and is related to the current user"
  end

end
