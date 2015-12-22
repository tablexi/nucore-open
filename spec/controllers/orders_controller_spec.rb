require "rails_helper"
require 'controller_spec_helper'

RSpec.describe OrdersController do
  include DateHelper

  render_views

  before(:all) { create_users }

  class DummyNotifier
    def deliver; end
  end


  it "should route" do
    expect({ :get => "/orders/cart" }).to route_to(:controller => "orders", :action => "cart")
    expect({ :get => "/orders/1" }).to route_to(:controller => "orders", :action => "show", :id => "1")
    expect({ :put => "/orders/1" }).to route_to(:controller => "orders", :action => "update", :id => "1")
    expect({ :put => "/orders/1/add" }).to route_to(:controller => "orders", :action => "add", :id => "1")
    expect({ :put => "/orders/1/remove/3" }).to route_to(:controller => "orders", :action => "remove", :id => "1", :order_detail_id => "3")
    expect({ :put => "/orders/1" }).to route_to(:controller => "orders", :action => "update", :id => "1")
    expect({ :put => "/orders/1/clear" }).to route_to(:controller => "orders", :action => "clear", :id => "1")
    expect({ :put => "/orders/1/purchase" }).to route_to(:controller => "orders", :action => "purchase", :id => "1")
    expect({ :get => "/orders/1/receipt" }).to route_to(:controller => "orders", :action => "receipt", :id => "1")
    expect({ :get => "/orders/1/choose_account" }).to route_to(:controller => "orders", :action => "choose_account", :id => "1")
  end

  before :each do
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @price_group      = @authable.price_groups.create(FactoryGirl.attributes_for(:price_group))
    @item = @authable.items.create(attributes_for(:item, facility_account_id: @facility_account.id))
    @account = add_account_for_user(:staff, @item, @price_group)
    @order            = @staff.orders.create(FactoryGirl.attributes_for(:order, :created_by => @staff.id, :account => @account))

    @item_pp=@item.item_price_policies.create!(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :start_date => 1.hour.ago))

    @params={ :id => @order.id, :order_id => @order.id }
  end

  let(:params) { @params }
  let(:order) { @order }

  context 'cart' do

    before :each do
      @method=:get
      @action=:cart
    end

    it_should_require_login

    it_should_allow :staff do
      assert_redirected_to order_url(@order)
    end

    context 'signed in' do
      before(:each) { sign_in @staff }

      context 'with an item' do
        before :each do
          @order.add(@item, 1)
        end

        it 'should redirect to the order' do
          do_request
          expect(request).to redirect_to order_url(@order)
        end
      end

      context 'cart with one reservation' do
        before :each do
          @instrument = FactoryGirl.create(:setup_instrument, :facility => @authable)
          @order.add(@instrument, 1)
          @res1 = FactoryGirl.create(:setup_reservation, :order_detail => @order.order_details[0], :product => @instrument)
        end

        it 'should redirect to a new cart' do
          do_request
          expect(request).not_to redirect_to order_url(@order)
        end

        context 'with a second reservation' do
          before :each do
            @instrument2 = FactoryGirl.create(:setup_instrument, :facility => @authable)
            @order.add(@instrument2, 1)
            @res2 = FactoryGirl.create(:setup_reservation, :order_detail => @order.order_details[2], :product => @instrument)
          end

          it 'should redirect to the existing cart' do
            do_request
            expect(request).to redirect_to order_url(@order)
          end
        end
      end
    end
  end


  context 'choose_account' do

    before :each do
      @order.add(@item, 1)
      expect(@order.order_details.size).to eq(1)

      @method=:get
      @action=:choose_account
      @params.merge!(:account_id => @account.id)
    end

    it_should_require_login

    it_should_allow :staff do
      expect(assigns(:order)).to be_kind_of Order
      expect(assigns(:order)).to eq(@order)
      is_expected.to render_template 'choose_account'
    end

    context 'staff logged in' do
      before :each do
        sign_in @staff
      end
      it 'should redirect to cart url if the cart is empty' do
        @order2 = @staff.orders.create(FactoryGirl.attributes_for(:order, :created_by => @staff.id, :account => @account))
        expect(@order2.order_details).to be_empty
        @params = { :id => @order2.id }
        do_request
        expect(response).to redirect_to cart_path
      end
    end
  end


  context "update on purchase" do
    before :each do
      @order_detail = place_product_order(@staff, @authable, @item, @account, false)
      @order = @order_detail.order

      # mimic visiting the cart
      @order.validate_order!

      # setup params
      @action = :purchase
      @method = :put
      @params={ :id => @order.id, :order_id => @order.id }

      sign_in @staff
    end

    context "update quantity" do
      before :each do
        #setup quantity update params
        @params["quantity#{@order_detail.id}"] = 5
        do_request
      end

      it "should update the quantity" do
        @order_detail.reload
        expect(@order_detail.quantity).to eq(5)
      end

      it "should redirect to the cart" do
        is_expected.to redirect_to order_path(@order)
      end

      it "should not purchase" do
        expect(assigns[:order].state).not_to eq("purchased")
      end
    end


    context "update quantities of multiple items while keeping total the same" do
      before :each do
        # modify first od quantity behind the scenes
        @order_detail1 = @order_detail
        @order_detail1.update_attributes(:quantity => 4)

        # add another item
        @order_detail2 = @order_detail1.order.add(@item, 3).first

        # mimic cart being visited
        @order.reload
        @order.validate_order!

        # set new quantities which are swapped in params
        @params["quantity#{@order_detail1.id}"] = @order_detail2.quantity
        @params["quantity#{@order_detail2.id}"] = @order_detail1.quantity

        do_request
      end

      it "should update the quantities" do
        @order_detail1.reload
        expect(@order_detail1.quantity).to eq(3)
        @order_detail2.reload
        expect(@order_detail2.quantity).to eq(4)
      end

      it "should redirect to the cart" do
        is_expected.to redirect_to order_path(@order)
      end

      it "should not purchase" do
        expect(assigns[:order].state).not_to eq("purchased")
      end
    end

    context "update note" do
      before :each do
        #setup note update params (have to also setup quantity params)
        @params["note#{@order_detail.id}"] = "note set on purchase"
        do_request
      end

      it "should update the note" do
        order_detail = assigns[:order].order_details.first
        order_detail.reload
        expect(order_detail.note).not_to be_blank
      end

      it "should purchase the order" do
        @order.reload
        expect(@order.state).to eq('purchased')
      end
    end

    context 'remove note' do
      let(:order_detail) { order.order_details.first }
      before do
        order_detail.update_attributes(note: 'old note')
        @action = :update
        params["note#{@order_detail.id}"] = ""
      end

      it 'removes the note' do
        do_request
        expect(order_detail.reload.note).to be_blank
      end
    end
  end

  context 'purchase' do

    before :each do
      @method=:put
      @action=:update_or_purchase
    end

    it_should_require_login

    it_should_allow :staff do
      expect(assigns(:order)).to be_kind_of Order
      expect(assigns(:order)).to eq(@order)
      is_expected.to respond_with :redirect
    end

    context 'success' do
      before :each do
        @instrument = FactoryGirl.create(:instrument,
                                            :facility => @authable,
                                            :facility_account => @facility_account,
                                            :no_relay => true)
        @instrument_pp = create :instrument_price_policy, :price_group => @nupg, product: @instrument
        define_open_account(@instrument.account, @account.account_number)
        @reservation = place_reservation_for_instrument(@staff, @instrument, @account, Time.zone.now)
        @order = @reservation.order_detail.order
        expect(@reservation.order_detail.order_status).to be_nil
        @params.merge!({:id => @order.id, :order_id => @order.id})
      end

      it 'should purchase the order' do
        sign_in @staff
        do_request
        expect(assigns[:order].state).to eq('purchased')
      end

      it 'should set the status of the order detail to the products default status' do
        sign_in @staff
        do_request
        expect(assigns[:order].order_details.size).to eq(1)
        expect(assigns[:order].order_details.first.order_status).to eq(OrderStatus.new_os.first)
      end

      it 'should set the status of the order detail to the products default status' do
        @order_status = FactoryGirl.create(:order_status, :parent => OrderStatus.inprocess.first)
        @instrument.update_attributes!(:initial_order_status_id => @order_status.id)
        sign_in @staff
        do_request
        expect(assigns[:order].order_details.size).to eq(1)
        expect(assigns[:order].order_details.first.order_status).to eq(@order_status)
      end

      it 'should redirect to my reservations on a successful purchase of a single reservation' do
        sign_in @staff
        do_request
        expect(flash[:notice]).to eq('Reservation completed successfully')
        expect(response).to redirect_to reservations_path
      end

      it 'should redirect to switch on if the instrument has a relay' do
        @instrument.update_attributes(:relay => FactoryGirl.create(:relay_dummy, :instrument => @instrument))
        sign_in @staff
        do_request
        expect(response).to redirect_to order_order_detail_reservation_switch_instrument_path(
          @order,
          @order_detail,
          @reservation,
          :switch => 'on',
          :redirect_to => reservations_path
          )
      end

      it 'should redirect to receipt when purchasing multiple reservations' do
        @order.add(@instrument, 1)
        expect(@order.order_details.size).to eq(2)
        @reservation2 = FactoryGirl.create(:reservation, :order_detail => @order.order_details[1], :product => @instrument)
        expect(Reservation.all.size).to eq(2)

        sign_in @staff
        do_request
        expect(response).to redirect_to receipt_order_url(@order)
      end
      it 'should redirect to receipt when acting as and ordering a single reservation' do
        sign_in @admin
        switch_to @staff
        do_request
        expect(response).to redirect_to receipt_order_url(@order)
      end

      describe 'notification sending' do
        it 'should send a notification' do
          expect(Notifier).to receive(:order_receipt).once.and_return(DummyNotifier.new)
          sign_in @admin
          do_request
        end

        it "should not send an email by default if you're acting as" do
          expect(Notifier).to receive(:order_receipt).never
          sign_in @admin
          switch_to @staff
          do_request
        end

        it "should not send an email if you're acting as and have the checkbox unchecked" do
          expect(Notifier).to receive(:order_receipt).never
          sign_in @admin
          switch_to @staff
          @params.merge!(:send_notification => '0')
          do_request
        end

        it "should send an email if you're acting as and set the parameter" do
          expect(Notifier).to receive(:order_receipt).once.and_return(DummyNotifier.new)
          sign_in @admin
          switch_to @staff
          @params.merge!(:send_notification => '1')
          do_request
        end
      end
    end

    context 'backdating' do
      before :each do
        @order_detail = place_product_order(@staff, @authable, @item, @account, false)
        @order.update_attribute(:ordered_at, nil)
        @params.merge!({:id => @order.id})
      end
      it 'should be set up correctly' do
        expect(@order.state).to eq('new')
        expect(@order_detail.state).to eq('new')
      end
      it 'should validate the order properly' do
        expect(@order).to be_has_details
        expect(@order).to be_has_valid_payment
        expect(@order).to be_cart_valid
      end
      it 'should validate and place order' do
        @order.validate_order!
        expect(@order).to be_place_order
      end
      it 'should redirect to order receipt on a successful purchase' do
        sign_in @staff
        do_request
        expect(flash[:error]).to be_nil
        expect(response).to redirect_to receipt_order_path(@order)
      end
      it 'should set the ordered at to the past' do
        maybe_grant_always_sign_in :director
        switch_to @staff
        @params.merge!({:order_date => format_usa_date(1.day.ago), :order_time => {:hour => '10', :minute => '12', :ampm => 'AM'}})
        do_request
        expect(assigns[:order].reload.ordered_at).to match_date 1.day.ago.change(:hour => 10, :min => 12)
      end
      it 'should set the ordered at to now if not acting_as' do
        maybe_grant_always_sign_in :director
        @params.merge!({:order_date => format_usa_date(1.day.ago)})
        do_request
        expect(assigns[:order].reload.ordered_at).to match_date Time.zone.now
      end

      context 'setting status of order details' do
        before :each do
          maybe_grant_always_sign_in :director
          switch_to @staff
        end
        it 'should leave as new by default' do
          do_request
          assigns[:order].reload.order_details.all? { |od| expect(od.state).to eq('new') }
        end
        it 'should leave as new if new is set as the param' do
          @params.merge!({:order_status_id => OrderStatus.new_os.first.id})
          do_request
          assigns[:order].reload.order_details.all? { |od| expect(od.state).to eq('new') }
        end
        it 'should be able to set to canceled' do
          @params.merge!({:order_status_id => OrderStatus.canceled.first.id})
          do_request
          assigns[:order].reload.order_details.all? { |od| expect(od.state).to eq('canceled') }
        end

        context 'completed' do
          before :each do
            @params.merge!({:order_status_id => OrderStatus.complete.first.id})
          end
          it 'should be able to set to completed' do
            do_request
            assigns[:order].reload.order_details.all? { |od| expect(od.state).to eq('complete') }
          end
          it 'should set reviewed_at if there is zero review period' do
            Settings.billing.review_period = 0.days
            do_request
            assigns[:order].reload.order_details.all? { |od| expect(od.reviewed_at).not_to be_nil }
            Settings.reload!
          end
          it 'should leave reviewed_at as nil if there is a review period' do
            Settings.billing.review_period = 7.days
            do_request
            assigns[:order].reload.order_details.all? { |od| expect(od.reviewed_at).to be_nil }
            Settings.reload!
          end
          it 'should set the fulfilled date to the order time' do
            @item_pp = @item.item_price_policies.create!(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :start_date => 1.day.ago, :expire_date => 1.day.from_now))
            @params.merge!({:order_date => format_usa_date(1.day.ago), :order_time => {:hour => '10', :minute => '13', :ampm => 'AM'}})
            do_request
            assigns[:order].reload.order_details.all? { |od| expect(od.fulfilled_at).to match_date 1.day.ago.change(:hour => 10, :min => 13) }
          end
          context 'price policies' do
            before :each do
              @item.item_price_policies.clear
              @item_pp = @item.item_price_policies.create!(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :start_date => 1.day.ago, :expire_date => 1.day.from_now))
              @item_past_pp=@item.item_price_policies.create!(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :start_date => 7.days.ago, :expire_date => 1.day.ago))
              @params.merge!(:order_time => {:hour => '10', :minute => '00', :ampm => 'AM'})
            end
            it 'should use the current price policy for dates in that policy' do
              @params.merge!({:order_date => format_usa_date(1.day.ago)})
              do_request
              assigns[:order].reload.order_details.all? { |od| expect(od.price_policy).to eq(@item_pp) }
            end
            it 'should use an old price policy for the past' do
              @params.merge!({:order_date => format_usa_date(5.days.ago)})
              do_request
              assigns[:order].reload.order_details.all? { |od| expect(od.price_policy).to eq(@item_past_pp) }
            end

            # when backdating was initially set up, this would cause an error, but behavior changed as of ticket #51239
            it 'should not have a problem even if there is no policy set for the date in the past' do
              @params.merge!({:order_date => format_usa_date(9.days.ago)})
              do_request
              assigns[:order].reload.order_details.all? do |od|
                expect(od.price_policy).to be_nil
                expect(od.actual_cost).to be_nil
                expect(od.actual_subsidy).to be_nil
                expect(od.state).to eq('complete')
              end
              expect(flash[:error]).to be_nil
              expect(response).to redirect_to receipt_order_url(@order)
            end
          end

        end
      end

      context 'backdating a reservation' do
        before :each do
          @instrument = FactoryGirl.create(:instrument,
                                              :facility => @authable,
                                              :facility_account => @facility_account)
          @instrument_pp = create :instrument_price_policy, price_group: @price_group, start_date: 7.day.ago, expire_date: 1.day.from_now, product: @instrument
          define_open_account(@instrument.account, @account.account_number)
          @reservation = place_reservation_for_instrument(@staff, @instrument, @account, 3.days.ago)
          expect(@reservation).not_to be_nil
          @params.merge!(:id => @reservation.order_detail.order.id)
          maybe_grant_always_sign_in :director
          switch_to @staff
          @params.merge!({:order_date => format_usa_date(2.days.ago), :order_time => {:hour => '2', :minute => '27', :ampm => 'PM'}})
          @submitted_date = 2.days.ago.change(:hour => 14, :min => 27)
        end
        it "should completed by default because it's in the past" do
          do_request
          assigns[:order].order_details.all? { |od| expect(od.state).to eq('complete') }
        end
        it 'should set the fulfilment date to the order time' do
          do_request
          assigns[:order].order_details.all? do |od|
            expect(od.fulfilled_at).not_to be_nil
            expect(od.fulfilled_at).to match_date @reservation.reserve_end_at
          end
        end
        it 'should set the actual times to the reservation times for completed' do
          do_request
          expect(@reservation.reload.actual_start_at).to match_date @reservation.reserve_start_at
          expect(@reservation.actual_end_at).to match_date(@reservation.reserve_start_at + 60.minutes)
        end
        it 'should assign a price policy and cost' do
          do_request
          expect(@order_detail.reload.price_policy).not_to be_nil
          expect(@order_detail.actual_cost).not_to be_nil
        end
        context 'canceled' do
          before :each do
            @params.merge!({:order_status_id => OrderStatus.canceled.first.id})
            do_request
          end
          it 'should be able to be set to canceled' do
            assigns[:order].order_details.all? { |od| expect(od.state).to eq('canceled') }
          end
          it 'should set the canceled time on the reservation' do
            assigns[:order].order_details.all? { |od| expect(od.reservation.canceled_at).not_to be_nil }
            expect(@reservation.reload.canceled_at).not_to be_nil
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
      expect(assigns(:order)).to be_kind_of Order
      expect(assigns(:order)).to eq(@complete_order)
      is_expected.to render_template 'receipt'
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
      expect(assigns(:order_details)).to be_kind_of ActiveRecord::Relation
      is_expected.to render_template 'index'
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
      end

      it_should_allow :staff, "to add a product with quantity to cart" do
        expect(assigns(:order).id).to eq(@order.id)
        expect(@order.reload.order_details.count).to eq(1)
        expect(flash[:error]).to be_nil
        expect(response).to redirect_to "/orders/#{@order.id}"
      end

      it_should_allow :staff, 'should assign an estimated price if there is a policy' do
        expect(@item.price_policies).not_to be_empty
        expect(@order.reload.order_details.first.estimated_cost).not_to be_nil
      end

    end

    context 'instrument' do
      before :each do
        @order.clear_cart?
        @instrument=FactoryGirl.create(:instrument,
                                          :facility => @authable,
                                          :facility_account => @facility_account,
                                          :min_reserve_mins => 60,
                                          :max_reserve_mins => 60)
        @params[:id]=@order.id
        @params[:order][:order_details].first[:product_id] = @instrument.id
      end

      it_should_allow :staff, "with empty cart (will use same order)" do
        expect(assigns(:order).id).to eq(@order.id)
        expect(flash[:error]).to be_nil

        assert_redirected_to new_order_order_detail_reservation_path(@order.id, @order.reload.order_details.first.id)
      end

      context "quantity = 2" do
        before :each do
          @params[:order][:order_details].first[:quantity] = 2
        end

        it_should_allow :staff, "with empty cart (will use same order) redirect to choose account" do
          expect(assigns(:order).id).to eq(@order.id)
          expect(flash[:error]).to be_nil

          assert_redirected_to choose_account_order_url(@order)
        end

      end

      context "with non-empty cart" do
        before :each do
          @order.add(@item, 1)
        end

        it_should_allow :staff, "with non-empty cart (will create new order)" do
          expect(assigns(:order)).not_to eq(@order)
          expect(flash[:error]).to be_nil

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
        expect(response).to redirect_to("/orders/#{@order.id}/choose_account")
      end

      it "should set session with contents of params[:order][:order_details]" do
        expect(session[:add_to_cart]).not_to be_empty
        expect(session[:add_to_cart]).to match_array([{"product_id" => @item.id.to_s, "quantity" => 1}])
      end
    end

    context "w/ account" do
      before :each do
        @order.account = @account
        @order.save!
      end

      context "mixed facility" do
        it "should flash error message containing another" do
          @facility2          = FactoryGirl.create(:facility)
          @facility_account2  = @facility2.facility_accounts.create!(FactoryGirl.attributes_for(:facility_account))
          @account2           = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @staff))
          @item2              = @facility2.items.create!(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account2.id))
          # add first item to cart
          maybe_grant_always_sign_in :staff
          do_request

          # add second item to cart
          @params.merge!(:order => {:order_details => [{:quantity => 1, :product_id => @item2.id}]})
          do_request

          is_expected.to set_flash.to(/can not/)
          is_expected.to set_flash.to(/another/)
          expect(response).to redirect_to "/orders/#{@order.id}"
        end
      end
    end

    context "acting_as" do
      before :each do
        @order.account = @account
        @order.save!
        @facility2          = FactoryGirl.create(:facility)
        @facility_account2  = @facility2.facility_accounts.create!(FactoryGirl.attributes_for(:facility_account))
        @account2           = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @staff))
        @item2              = @facility2.items.create!(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account2.id))
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
            is_expected.not_to set_flash
            expect(@order.reload.order_details).not_to be_empty
            expect(response).to redirect_to "/orders/#{@order.id}"
          end
        end
        it "should not allow guest" do
          maybe_grant_always_sign_in :guest
          @guest2 = FactoryGirl.create(:user)
          switch_to @guest2
          do_request
          is_expected.to set_flash
          expect(@order.reload.order_details).to be_empty
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
          expect(@order.reload.order_details).to be_empty
          is_expected.to set_flash.to(/You are not authorized to place an order on behalf of another user for the facility/)
        end
      end
    end
  end

  context "remove from cart" do
    before(:each) do
      @order.add(@item, 1)
      expect(@order.order_details.size).to eq(1)
      @order_detail = @order.order_details[0]

      @method=:put
      @action=:remove
      @params.merge!(:order_detail_id => @order_detail.id)
    end

    it_should_require_login

    it_should_allow :staff, "should delete an order_detail when /remove/:order_detail_id is called" do
      expect(@order.reload.order_details.size).to eq(0)
      expect(response).to redirect_to "/orders/#{@order.id}"
    end

    it "should 404 it the order_detail to be removed is not in the current cart" do
      @account2 = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @director))
      @order2   = @director.orders.create(FactoryGirl.attributes_for(:order, :user => @director, :created_by => @director.id, :account => @account2))
      @order2.add(@item)
      @order_detail2 = @order2.order_details[0]
      @params[:order_detail_id]=@order_detail2.id
      maybe_grant_always_sign_in :staff
      do_request
      expect(response.response_code).to eq(404)
    end

    context "removing last item in cart" do
      it "should nil out the payment source in the order/session" do
        maybe_grant_always_sign_in :staff
        do_request

        expect(response).to redirect_to "/orders/#{@order.id}"
        is_expected.to set_flash.to /removed/

        expect(@order.reload.order_details.size).to eq(0)
        expect(@order.reload.account).to eq(nil)
      end
    end

    it "should redirect to the value of the redirect_to param if available" do
      maybe_grant_always_sign_in :staff
      overridden_redirect = facility_url(@item.facility)

      @params.merge!(:redirect_to => overridden_redirect)
      do_request

      expect(response).to redirect_to overridden_redirect
      is_expected.to set_flash.to /removed/
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
      expect(@order_detail.reload.quantity).to eq(6)
    end

    context "bad input" do
      it "should show an error on not an integer" do
        @params.merge!("quantity#{@order_detail.id}" => "1.5")
        maybe_grant_always_sign_in :guest
        do_request
        is_expected.to set_flash.to(/quantity/i)
        is_expected.to set_flash.to(/integer/i)
        is_expected.to render_template :show
      end


    end

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
      expect(@order_detail.reload.note).to eq('new note')
    end
  end

  context "cart meta data" do
    before(:each) do
      @instrument   = FactoryGirl.create(:instrument,
                                          :facility => @authable,
                                          :facility_account => @facility_account)

      @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, :start_hour => 0, :end_hour => 24))
      @instrument_pp = @instrument.instrument_price_policies.create(FactoryGirl.attributes_for(:instrument_price_policy, :price_group_id => @price_group.id))
      @instrument_pp.restrict_purchase = false
      define_open_account(@instrument.account, @account.account_number)
      @service          = @authable.services.create(FactoryGirl.attributes_for(:service, :facility_account_id => @facility_account.id))
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
        expect(response).to be_success
      end
    end

    context "restricted instrument" do
      before :each do
        @instrument.update_attributes(:requires_approval => true)
        @order.update_attributes(:created_by_user => @director, :account => @account)
        @order.add(@instrument)
        expect(@order.order_details.size).to eq(1)
        @params.merge!(:id => @order.id)
      end
      it 'should not allow purchasing a restricted item' do
        maybe_grant_always_sign_in :guest
        place_reservation(@authable, @order.order_details.first, Time.zone.now)
        #place reservation makes the @order purchased
        @order.reload.update_attributes!(:state => 'new')
        do_request
        expect(assigns[:order]).to eq(@order)
        expect(assigns[:order]).not_to be_validated
      end
      it "should allow purchasing a restricted item the user isn't authorized for" do
        place_reservation(@authable, @order.order_details.first, Time.zone.now)
        #place reservation makes the @order purchased
        @order.reload.update_attributes!(:state => 'new')
        maybe_grant_always_sign_in :director
        switch_to @guest
        do_request
        expect(response.code).to eq('200')
        expect(assigns[:order]).to eq(@order)
        expect(assigns[:order]).to be_validated
      end
      it "should not be validated if there is no reservation" do
        maybe_grant_always_sign_in :director
        do_request
        expect(response).to be_success
        expect(assigns[:order]).not_to be_validated
        expect(assigns[:order]).to eq(@order)
        expect(assigns[:order].order_details.first.validate_for_purchase).to eq("Please make a reservation")
      end
    end
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
      #@item_pp          = FactoryGirl.create(:item_price_policy, :item => @item, :price_group => @price_group)
      #@pg_member        = FactoryGirl.create(:user_price_group_member, :user => @staff, :price_group => @price_group)
      @order.add(@item, 10)
      @method=:get
      @action=:show
    end

    it_should_require_login

    it "should disallow viewing of cart that is purchased" do
      FactoryGirl.create(:price_group_product, :product => @item, :price_group =>@price_group, :reservation_window => nil)
      define_open_account(@item.account, @account.account_number)
      @order.validate_order!
      @order.purchase!
      maybe_grant_always_sign_in :staff
      do_request
      expect(response).to redirect_to "/orders/#{@order.id}/receipt"

      @action=:choose_account
      do_request
      expect(response).to redirect_to "/orders/#{@order.id}/receipt"

      @method=:put
      @action=:purchase
      do_request
      expect(response).to redirect_to "/orders/#{@order.id}/receipt"

      # TODO: add, etc.
    end

    it 'should set the potential order_statuses from this facility and only this facility' do
      maybe_grant_always_sign_in :staff
      @facility2 = FactoryGirl.create(:facility)
      @order_status = FactoryGirl.create(:order_status, :facility => @authable, :parent => OrderStatus.new_os.first)
      @order_status_other = FactoryGirl.create(:order_status, :facility => @facility2, :parent => OrderStatus.new_os.first)
      do_request
      expect(assigns[:order_statuses]).to be_include @order_status
      expect(assigns[:order_statuses]).not_to be_include @order_status_other
    end

  end

end
