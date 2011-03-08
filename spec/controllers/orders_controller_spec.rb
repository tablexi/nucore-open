require 'spec_helper'; require 'controller_spec_helper'

describe OrdersController do
  integrate_views

  before(:all) { create_users }


  it "should route" do
    params_from(:get, "/orders/cart").should == {:controller => "orders", :action => "cart"}
    params_from(:get, "/orders/1").should    == {:controller => "orders", :action => "show", :id => "1"}
    params_from(:put, "/orders/1").should    == {:controller => "orders", :action => "update", :id => "1"}
    params_from(:put, "/orders/1/add").should == {:controller => "orders", :action => "add", :id => "1"}
    params_from(:put, "/orders/1/remove/3").should == {:controller => "orders", :action => "remove", :id => "1", :order_detail_id => "3"}
    params_from(:put, "/orders/1").should == {:controller => "orders", :action => "update", :id => "1"}
    params_from(:put, "/orders/1/clear").should == {:controller => "orders", :action => "clear", :id => "1"}
    params_from(:put, "/orders/1/purchase").should == {:controller => "orders", :action => "purchase", :id => "1"}
    params_from(:get, "/orders/1/receipt").should == {:controller => "orders", :action => "receipt", :id => "1"}
    params_from(:get, "/orders/1/choose_account").should == {:controller => "orders", :action => "choose_account", :id => "1"}
  end

  context "add to cart" do
    before(:each) do
      @facility1         = Factory.create(:facility)
      @facility_account1 = @facility1.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group1      = @facility1.price_groups.create(Factory.attributes_for(:price_group))
      @user1             = Factory.create(:user)
      @account1          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user1, :created_by => @user1, :user_role => 'Owner']])
      @order1            = @user1.orders.create(Factory.attributes_for(:order, :created_by => @user1.id, :account => @account1))
      @item1             = @facility1.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account1.id))
      @item_pp           = Factory.create(:item_price_policy, :item => @item1, :price_group => @price_group1)
      @pg_member         = Factory.create(:user_price_group_member, :user => @user1, :price_group => @price_group1)

      @facility2         = Factory.create(:facility)
      @facility_account2 = @facility2.facility_accounts.create(Factory.attributes_for(:facility_account))
      @item2             = @facility2.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account2.id))

      sign_in @admin
      User.stubs(:find).returns(@user1)
    end

    context "no account" do
      it "should redirect to choose_account when /add/:product_id/:quantity is called and cart doesn't have an account" do
        @order1.account = nil
        @order1.save
        put :add, :id => @order1.id, :quantity => 10, :product_id => @item1.id
        response.should redirect_to("/orders/#{@order1.id}/choose_account")
      end
    end

    context "cart has an account" do
      it "should add a product with quantity to cart PUT /add/:product_id/:quantity" do
        put :add, :id => @order1.id, :quantity => 1, :product_id => @item1.id
        assigns[:order].should == @order1
        assigns[:product].should == @item1
        @order1.reload.order_details.size.should == 1
        response.should redirect_to "/orders/#{@order1.id}"
      end
    end

    context "cart with mixed facility" do
      it "should show mixed facility warning if added product doesn't match cart facility" do
        put :add, :id => @order1.id, :quantity => 1, :product_id => @item1.id
        put :add, :id => @order1.id, :quantity => 1, :product_id => @item2.id
        flash[:error].should == "You can not add a product from another facility; please clear your cart or place a separate order."
        response.should redirect_to "/orders/#{@order1.id}"
      end
    end

    it "should show a warning if the user doesn't have access to the product to be added" do
      pending
    end
  end

  context "choose account" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user             = Factory.create(:user)
      @order            = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
      @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))

      sign_in @admin
      User.stubs(:find).returns(@user)
    end

    it "should set account on post to set_account" do
      pending
#      put :add, :id => @order.id, :product_id => @item.id, :quantity => 1
#      response.should redirect_to :add_account
    end

    it "should 403 if account is not in current user's accessible accounts"
  end

  context "remove from cart" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @user1            = Factory.create(:user)
      @account1         = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user1, :created_by => @user1, :user_role => 'Owner']])
      @order1           = @user1.orders.create(Factory.attributes_for(:order, :user => @user1, :created_by => @user1, :account => @account1))

      @user2    = Factory.create(:user)
      @account2 = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user2, :created_by => @user2, :user_role => 'Owner']])
      @order2   = @user2.orders.create(Factory.attributes_for(:order, :user => @user2, :created_by => @user2, :account => @account2))

      @item      = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @item_pp   = Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      @pg_member = Factory.create(:user_price_group_member, :user => @user1, :price_group => @price_group)
      @pg_member = Factory.create(:user_price_group_member, :user => @user2, :price_group => @price_group)
    end

    it "should delete an order_detail when /remove/:order_detail_id is called" do
      @order1.add(@item, 1)
      @order1.order_details.size.should == 1
      @order_detail = @order1.order_details[0]
      sign_in @admin
      User.stubs(:find).returns(@user1)
      put :remove, :id => @order1.id, :order_detail_id => @order_detail.id
      @order1.reload.order_details.size.should == 0
      response.should redirect_to "/orders/#{@order1.id}"
    end

    it "should 404 it the order_detail to be removed is not in the current cart" do
      @order1.add(@item)
      @order2.add(@item)
      @order_detail2 = @order2.order_details[0]

      sign_in @admin
      User.stubs(:find).returns(@user1)
      put :remove, :id => @order1.id, :order_detail_id => @order_detail2.id
      response.response_code.should == 404
    end
  end

  context "update order_detail quantities" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @user1            = Factory.create(:user)
      @account1         = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user1, :created_by => @user1, :user_role => 'Owner']])
      @order1           = @user1.orders.create(Factory.attributes_for(:order, :user => @user1, :created_by => @user1.id, :account => @account1))

      @item      = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @item_pp   = Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      @pg_member = Factory.create(:user_price_group_member, :user => @user1, :price_group => @price_group)

      sign_in @admin
      User.stubs(:find).returns(@user1)
    end

    it "should update the quantities of order_details" do
      @user1.cart.add(@item,1)
      @order_detail = @order1.reload.order_details[0]
      @order_detail.quantity.should == 1
      put :update, :id => @order1.id, "quantity#{@order_detail.id}" => "6"
      @order_detail.reload.quantity.should == 6
    end

    it "should not allow updates of quantities for instruments" do
      pending
    end
  end

  context "cart meta data" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @user             = Factory.create(:user)
      @account          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order            = @user.orders.create(Factory.attributes_for(:order, :user => @user, :created_by => @user.id, :account => @account))

      @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @service          = @facility.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
      @service_pp       = Factory.create(:service_price_policy, :service => @service, :price_group => @price_group)
      @pg_member        = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))

      sign_in @admin
      User.stubs(:find).returns(@user)
    end

    it "should show links for making a reservation for instruments" do
      @order.add(@instrument)
      @order_detail = @order.order_details.first
      get :show, :id => @order.id
      response.should have_tag 'a[href=?]', new_order_order_detail_reservation_path(@order, @order_detail)
    end

    it "should show links for uploading files for services where required by service"

    it "should show links for add survey metadata for services requiring a survey" do
      # add survey, make it active
      @survey = Survey.create(:title => "Survey 1", :access_code => '1234')
      @service.surveys.push(@survey)
      @service.service_surveys.first.active!
      @order.add(@service)
      @order_detail = @order.order_details.first
      get :show, :id => @order.id
      response.should have_tag 'a[href=?]', "/orders/#{@order.id}/details/#{@order_detail.id}/surveys/#{@survey.access_code}"
    end

    it "should show links for edit survey metadata if survey has been completed" do
      # add survey, make it active, create response set, mark it completed and add it to order detail
      @survey = Survey.create(:title => "Survey 1", :access_code => '1234')
      @service.surveys.push(@survey)
      @service.service_surveys.first.active!
      @response_set = @survey.response_sets.create(:access_code => 'set1')
      @response_set.complete!
      @response_set.save
      @order.add(@service)
      @order_detail = @order.order_details.first
      @order_detail.response_set!(@response_set)
      get :show, :id => @order.id
    end
  end

  context "clear" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @user             = Factory.create(:user)
      @account          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order            = @user.orders.create(Factory.attributes_for(:order, :user => @user, :created_by => @user.id, :account => @account))

      @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @item_pp          = Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      @pg_member        = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)

      sign_in @admin
      User.stubs(:find).returns(@user)

      @order.add(@item, 10)
    end

    it "should clear the cart and redirect back to cart" do
      put :clear, :id => @order.id
      @order.order_details.size == 0
      response.should redirect_to order_path(@order)
    end

  end

  context "checkout" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @user             = Factory.create(:user)
      @account          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order            = @user.orders.create(Factory.attributes_for(:order, :user => @user, :created_by => @user.id, :account => @account))
      @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @item_pp          = Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      @pg_member        = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @order.add(@item, 10)

      sign_in @admin
      User.stubs(:find).returns(@user)
    end

    it "should not allow viewing of cart that is purchased" do
      define_open_account(@item.account, @account.account_number)
      @order.validate_order!
      @order.purchase!
      get :show, :id => @order.id
      response.should redirect_to "/orders/#{@order.id}/receipt"

      get :choose_account, :id => @order.id
      response.should redirect_to "/orders/#{@order.id}/receipt"

      put :purchase, :id => @order.id
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
