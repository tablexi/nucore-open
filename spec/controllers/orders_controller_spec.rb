require 'spec_helper'; require 'controller_spec_helper'

describe OrdersController do
  include DateHelper

  render_views

  before(:all) { create_users }

  class DummyNotifier
    def deliver; end
  end


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
    define_open_account(@item.account, @account.account_number)

    Factory.create(:user_price_group_member, :user => @staff, :price_group => @price_group)
    @item_pp=@item.item_price_policies.create(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :start_date => 1.month.ago))

    @params={ :id => @order.id, :order_id => @order.id }
  end


  context 'cart' do

    before :each do
      @method=:get
      @action=:cart
    end

    it_should_require_login

    it_should_allow :staff do
      assert_redirected_to order_url(@order)
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

    context 'success' do
      before :each do
        @instrument = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
        @instrument_pp = @instrument.instrument_price_policies.create!(Factory.attributes_for(:instrument_price_policy, :price_group => @nupg))
        define_open_account(@instrument.account, @account.account_number)
        @reservation = place_reservation_for_instrument(@staff, @instrument, @account, Time.zone.now)
        @order = @reservation.order_detail.order
        @params.merge!({:id => @order.id, :order_id => @order.id})
      end

      it 'should redirect to my reservations on a successful purchase of a single reservation' do
        sign_in @staff
        do_request
        flash[:notice].should == 'Reservation completed successfully'
        response.should redirect_to reservations_path
      end
      it 'should redirect to receipt when purchasing multiple reservations' do
        @order.add(@instrument, 1)
        @order.order_details.size.should == 2
        @reservation2 = Factory.create(:reservation, :order_detail => @order.order_details[1], :instrument => @instrument)
        Reservation.all.size.should == 2

        sign_in @staff
        do_request
        response.should redirect_to receipt_order_url(@order)
      end
      it 'should redirect to receipt when acting as and ordering a single reservation' do
        sign_in @admin
        switch_to @staff
        do_request
        response.should redirect_to receipt_order_url(@order)
      end
      it 'should send a notification' do
        Notifier.expects(:order_receipt).once.returns(DummyNotifier.new)
        sign_in @admin
        do_request
      end
      it "should not send an email by default if you're acting as" do
        Notifier.expects(:order_receipt).never
        sign_in @admin
        switch_to @staff
        do_request
      end
      it "should send an email if you're acting as and set the parameter" do
        Notifier.expects(:order_receipt).once.returns(DummyNotifier.new)
        sign_in @admin
        switch_to @staff
        @params.merge!(:send_notification => '1')
        do_request
      end

    end

    context 'backdating' do
      before :each do
        @order_detail = place_product_order(@staff, @authable, @item, @account)
        @order.update_attribute(:ordered_at, nil)
        @params.merge!({:id => @order.id})
      end
      it 'should be set up correctly' do
        @order.state.should == 'new'
        @order_detail.state.should == 'new'
      end
      it 'should validate the order properly' do
        @order.should be_has_details
        @order.should be_has_valid_payment
        @order.should be_cart_valid
      end
      it 'should validate and place order' do
        @order.validate_order!
        @order.should be_place_order
      end
      it 'should redirect to order receipt on a successful purchase' do
        sign_in @staff
        do_request
        flash[:error].should be_nil
        response.should redirect_to receipt_order_path(@order)
      end
      it 'should set the ordered at to the past' do
        maybe_grant_always_sign_in :director
        switch_to @staff
        @params.merge!({:order_date => format_usa_date(1.day.ago), :order_time => {:hour => '10', :minute => '12', :ampm => 'AM'}})
        do_request
        assigns[:order].reload.ordered_at.should match_date 1.day.ago.change(:hour => 10, :min => 12)
      end
      it 'should set the ordered at to now if not acting_as' do
        maybe_grant_always_sign_in :director
        @params.merge!({:order_date => format_usa_date(1.day.ago)})
        do_request
        assigns[:order].reload.ordered_at.should match_date Time.zone.now
      end

      context 'setting status of order details' do
        before :each do
          maybe_grant_always_sign_in :director
          switch_to @staff
        end
        it 'should leave as new by default' do
          do_request
          assigns[:order].reload.order_details.all? { |od| od.state.should == 'new' }
        end
        it 'should leave as new if new is set as the param' do
          @params.merge!({:order_status_id => OrderStatus.new_os.first.id})
          do_request
          assigns[:order].reload.order_details.all? { |od| od.state.should == 'new' }
        end
        it 'should be able to set to cancelled' do
          @params.merge!({:order_status_id => OrderStatus.cancelled.first.id})
          do_request
          assigns[:order].reload.order_details.all? { |od| od.state.should == 'cancelled' }
        end
        
        context 'completed' do
          before :each do
            @params.merge!({:order_status_id => OrderStatus.complete.first.id})
          end
          it 'should be able to set to completed' do
            do_request
            assigns[:order].reload.order_details.all? { |od| od.state.should == 'complete' }
          end
          it 'should set reviewed_at if there is zero review period' do
            Settings.billing.review_period = 0.days
            do_request
            assigns[:order].reload.order_details.all? { |od| od.reviewed_at.should_not be_nil }
            Settings.reload!
          end
          it 'should leave reviewed_at as nil if there is a review period' do
            Settings.billing.review_period = 7.days
            do_request
            assigns[:order].reload.order_details.all? { |od| od.reviewed_at.should be_nil }
            Settings.reload!
          end
          it 'should set the fulfilled date to the order time' do
            @item_pp = @item.item_price_policies.create!(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :start_date => 1.day.ago, :expire_date => 1.day.from_now))
            @params.merge!({:order_date => format_usa_date(1.day.ago), :order_time => {:hour => '10', :minute => '13', :ampm => 'AM'}})
            do_request
            assigns[:order].reload.order_details.all? { |od| od.fulfilled_at.should match_date 1.day.ago.change(:hour => 10, :min => 13) }
          end
          context 'price policies' do
            before :each do
              @item.item_price_policies.clear
              @item_pp = @item.item_price_policies.create!(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :start_date => 1.day.ago, :expire_date => 1.day.from_now))
              @item_past_pp=@item.item_price_policies.create!(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :start_date => 7.days.ago, :expire_date => 1.day.ago))
              @params.merge!(:order_time => {:hour => '10', :minute => '00', :ampm => 'AM'})
            end
            it 'should use the current price policy for dates in that policy' do
              @params.merge!({:order_date => format_usa_date(Time.zone.now)})
              do_request
              assigns[:order].reload.order_details.all? { |od| od.price_policy.should == @item_pp }
            end
            it 'should use an old price policy for the past' do
              @params.merge!({:order_date => format_usa_date(5.days.ago)})
              do_request
              assigns[:order].reload.order_details.all? { |od| od.price_policy.should == @item_past_pp }
            end
            it 'should have a problem if there is no policy set for the date in the past' do
              @params.merge!({:order_date => format_usa_date(9.days.ago)})
              do_request
              assigns[:order].reload.order_details.all? do |od|
                od.price_policy.should be_nil
                od.actual_cost.should be_nil
                od.actual_subsidy.should be_nil
                od.state.should == 'new'
              end
              flash[:error].should_not be_nil
              response.should redirect_to order_url(@order)
            end
          end
          
        end
      end

      context 'backdating a reservation' do
        before :each do
          @instrument = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
          @instrument_pp = @instrument.instrument_price_policies.create!(Factory.attributes_for(:instrument_price_policy, :price_group => @price_group, :start_date => 7.day.ago, :expire_date => 1.day.from_now))
          define_open_account(@instrument.account, @account.account_number)
          @reservation = place_reservation_for_instrument(@staff, @instrument, @account, 3.days.ago)
          @reservation.should_not be_nil
          @params.merge!(:id => @reservation.order_detail.order.id)
          maybe_grant_always_sign_in :director
          switch_to @staff
          @params.merge!({:order_date => format_usa_date(2.days.ago), :order_time => {:hour => '2', :minute => '27', :ampm => 'PM'}})
          @submitted_date = 2.days.ago.change(:hour => 14, :min => 27)
        end
        it "should completed by default because it's in the past" do
          do_request
          assigns[:order].order_details.all? { |od| od.state.should == 'complete' }
        end
        it 'should set the fulfilment date to the order time' do
          do_request
          assigns[:order].order_details.all? do |od| 
            od.fulfilled_at.should_not be_nil
            od.fulfilled_at.should match_date @reservation.reserve_end_at
          end
        end
        it 'should set the actual times to the reservation times for completed' do
          do_request
          @reservation.reload.actual_start_at.should match_date @reservation.reserve_start_at
          @reservation.actual_end_at.should match_date(@reservation.reserve_start_at + 60.minutes)
        end
        it 'should assign a price policy and cost' do
          do_request
          @order_detail.reload.price_policy.should_not be_nil
          @order_detail.actual_cost.should_not be_nil
        end
        context 'cancelled' do
          before :each do
            @params.merge!({:order_status_id => OrderStatus.cancelled.first.id})
            do_request
          end
          it 'should be able to be set to cancelled' do
            assigns[:order].order_details.all? { |od| od.state.should == 'cancelled' }
          end
          it 'should set the cancelled time on the reservation' do
            assigns[:order].order_details.all? { |od| od.reservation.canceled_at.should_not be_nil }
            @reservation.reload.canceled_at.should_not be_nil
            # Should this match the date put in the form, or the date when the action took place
            # @reservation.canceled_at.should match_date @submitted_date
          end
        end
      end
    end
  end


  context 'receipt' do

    before :each do
      # for receipt to work, order needs to have order_details
      @complete_order = place_and_complete_item_order(@staff, @authable, @account).order.reload
      @method=:get
      @action=:receipt
      @params={:id => @complete_order.id}
    end

    it_should_require_login

    it_should_allow :staff do
      should assign_to(:order).with_kind_of Order
      assigns(:order).should == @complete_order
      should render_template 'receipt'
    end

  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
      @params={:status => 'pending'}
    end

    it_should_require_login

    it_should_allow :staff do
      should assign_to(:order_details).with_kind_of ActiveRecord::Relation
      should render_template 'index'
    end

  end


  context "add to cart" do
    before(:each) do
      @method=:put
      @action=:add
      @params.merge!(:order => {:order_details => [{:quantity => 1, :product_id => @item.id}]})
      @order.clear_cart?
    end

    it_should_require_login

    context "with account (having already gone through choose_account)" do
      before :each do
        @order.account = @account
        assert @order.save
        session[:add_to_cart] = nil
        do_request
      end

      it_should_allow :staff, "to add a product with quantity to cart" do
        assigns(:order).id.should == @order.id
        @order.reload.order_details.count.should == 1
        flash[:error].should be_nil
        should set_the_flash
        response.should redirect_to "/orders/#{@order.id}"
      end
    end

    context 'instrument' do
      before :each do
        @options=Factory.attributes_for(:instrument, :facility_account => @facility_account, :min_reserve_mins => 60, :max_reserve_mins => 60)
        @order.clear_cart?
        @instrument=@authable.instruments.create(@options)
        @params[:id]=@order.id
        @params[:order][:order_details].first[:product_id] = @instrument.id
      end

      it_should_allow :staff, "with empty cart (will use same order)" do
        assigns(:order).id.should == @order.id
        flash[:error].should be_nil

        assert_redirected_to new_order_order_detail_reservation_path(@order.id, @order.reload.order_details.first.id)
      end

      context "quantity = 2" do
        before :each do
          @params[:order][:order_details].first[:quantity] = 2
        end

        it_should_allow :staff, "with empty cart (will use same order) redirect to choose account" do
          assigns(:order).id.should == @order.id
          flash[:error].should be_nil

          assert_redirected_to choose_account_order_url(@order)
        end

      end

      context "with non-empty cart" do
        before :each do
          @order.add(@item, 1)
        end

        it_should_allow :staff, "with non-empty cart (will create new order)" do
          assigns(:order).should_not == @order
          flash[:error].should be_nil

          assert_redirected_to new_order_order_detail_reservation_path(assigns(:order), assigns(:order).order_details.first)
        end
      end
    end

    context "add is called and cart doesn't have an account" do
      before :each do
        @order.account = nil
        @order.save
        maybe_grant_always_sign_in :staff
        do_request
      end

      it "should redirect to choose account" do
        response.should redirect_to("/orders/#{@order.id}/choose_account")
      end

      it "should set session with contents of params[:order][:order_details]" do
        session[:add_to_cart].should_not be_empty
        session[:add_to_cart].should == [{"product_id" => @item.id, "quantity" => 1}]
      end
    end

    context "w/ account" do
      before :each do
        @order.account = @account
        @order.save!
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
          @params.merge!(:order => {:order_details => [{:quantity => 1, :product_id => @item2.id}]})
          do_request

          should set_the_flash.to(/can not/)
          should set_the_flash.to(/another/)
          response.should redirect_to "/orders/#{@order.id}"  
        end
      end
    end

    context "acting_as" do
      before :each do
        @order.account = @account
        @order.save!
        @facility2          = Factory.create(:facility)
        @facility_account2  = @facility2.facility_accounts.create!(Factory.attributes_for(:facility_account))
        @account2           = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @staff, :created_by => @staff, :user_role => AccountUser::ACCOUNT_OWNER]])
        @item2              = @facility2.items.create!(Factory.attributes_for(:item, :facility_account_id => @facility_account2.id))
      end
      context "in the right facility" do
        before :each do
          @params.merge!(:order => {:order_details => [{:quantity => 1, :product_id => @item.id}]})
        end
        facility_operators.each do |role|
          it "should allow #{role} to purchase" do
            maybe_grant_always_sign_in role
            switch_to @guest
            do_request
            should_not set_the_flash
            @order.reload.order_details.should_not be_empty
            response.should redirect_to "/orders/#{@order.id}"
          end
        end
        it "should not allow guest" do
          maybe_grant_always_sign_in :guest
          @guest2 = Factory.create(:user)
          switch_to @guest2
          do_request
          should set_the_flash
          @order.reload.order_details.should be_empty
        end
      end
      context "in the another facility" do
        before :each do
          maybe_grant_always_sign_in :director
          switch_to @guest
          @params.merge!(:order => {:order_details => [{:quantity => 1, :product_id => @item2.id}]})
        end

        it "should not allow ordering" do
          do_request
          @order.reload.order_details.should be_empty
          should set_the_flash.to(/You are not authorized to place an order on behalf of another user for the facility/)
        end
      end
      it "should show a warning if the user doesn't have access to the product to be added"
    end
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

    it "should redirect to the value of the redirect_to param if available" do
      maybe_grant_always_sign_in :staff
      overridden_redirect = facility_url(@item.facility)

      @params.merge!(:redirect_to => overridden_redirect)
      do_request

      response.should redirect_to overridden_redirect
      should set_the_flash.to /removed/
    end

  end


  context "update order_detail quantities" do
    before(:each) do
      @method=:put
      @action=:update
      @order_detail = @order.add(@item, 1).first
      @params.merge!("quantity#{@order_detail.id}" => "6")
    end

    it_should_require_login

    it_should_allow :staff, "to update the quantities of order_details" do
      @order_detail.reload.quantity.should == 6
    end

    context "bad input" do
      it "should show an error on not an integer" do
        @params.merge!("quantity#{@order_detail.id}" => "1.5")
        maybe_grant_always_sign_in :guest
        do_request
        should set_the_flash.to(/quantity/i)
        should set_the_flash.to(/integer/i)
        should render_template :show
      end
      

    end

    it "should not allow updates of quantities for instruments"
  end

  context "update order_detail notes" do
    before(:each) do
      @method=:put
      @action=:update
      @order_detail = @order.add(@item, 1).first
      @params.merge!(
        "quantity#{@order_detail.id}" => "6",
        "note#{@order_detail.id}" => "new note"
      )
    end

    it_should_require_login

    it_should_allow :staff, "to update the note field of order_details" do
      @order_detail.reload.note.should == 'new note'
    end
  end

  context "cart meta data" do
    before(:each) do
      @instrument       = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :start_hour => 0, :end_hour => 24))
      @instrument_pp = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :price_group_id => @price_group.id))
      @instrument_pp.restrict_purchase = false
      define_open_account(@instrument.account, @account.account_number)
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

    context "restricted instrument" do
      before :each do
        @instrument.update_attributes(:requires_approval => true)
        @order.update_attributes(:created_by_user => @director, :account => @account)
        @order.add(@instrument)
        @order.order_details.size.should == 1
        @params.merge!(:id => @order.id)
      end
      it 'should not allow purchasing a restricted item' do
        maybe_grant_always_sign_in :guest
        place_reservation(@authable, @order.order_details.first, Time.zone.now)
        #place reservation makes the @order purchased
        @order.reload.update_attributes!(:state => 'new')
        do_request
        assigns[:order].should == @order
        assigns[:order].should_not be_validated
      end
      it "should allow purchasing a restricted item the user isn't authorized for" do
        place_reservation(@authable, @order.order_details.first, Time.zone.now)
        #place reservation makes the @order purchased
        @order.reload.update_attributes!(:state => 'new')
        maybe_grant_always_sign_in :director
        switch_to @guest
        do_request
        response.code.should == '200'
        assigns[:order].should == @order
        assigns[:order].should be_validated
      end
      it "should not be validated if there is no reservation" do
        maybe_grant_always_sign_in :director
        do_request
        response.should be_success
        assigns[:order].should_not be_validated
        assigns[:order].should == @order
        assigns[:order].order_details.first.validate_for_purchase.should == "Please make a reservation"
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
      #@item_pp          = Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
      #@pg_member        = Factory.create(:user_price_group_member, :user => @staff, :price_group => @price_group)
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

    it 'should set the potential order_statuses from this facility and only this facility' do
      maybe_grant_always_sign_in :staff
      @facility2 = Factory.create(:facility)
      @order_status = Factory.create(:order_status, :facility => @authable, :parent => OrderStatus.new_os.first)
      @order_status_other = Factory.create(:order_status, :facility => @facility2, :parent => OrderStatus.new_os.first)
      do_request
      assigns[:order_statuses].should be_include @order_status
      assigns[:order_statuses].should_not be_include @order_status_other
    end

    it "should validate and transition to validated"

    it "should only allow checkout if the cart has at least one order_detail"
  end

  context "receipt /receipt/:order_id" do
    it "should 404 unless :order_id exists and is related to the current user"
  end

end
