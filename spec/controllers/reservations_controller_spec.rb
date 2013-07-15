require 'spec_helper'
require 'controller_spec_helper'

describe ReservationsController do
  include DateHelper

  render_views

  before(:all) { create_users }

  before(:each) do
    setup_instrument
    setup_user_for_purchase(@guest, @price_group)

    @order            = @guest.orders.create(FactoryGirl.attributes_for(:order, :created_by => @guest.id, :account => @account))
    @order.add(@instrument, 1)
    @order_detail     = @order.order_details.first
    assert @order_detail.persisted?

    @params={ :order_id => @order.id, :order_detail_id => @order_detail.id }
  end


  context 'index' do

    before :each do
      @order.stub(:cart_valid?).and_return(true)
      @order.stub(:place_order?).and_return(true)
      @order.validate_order!
      @order.purchase!

      @method=:get
      @action=:index
      @params.merge!(:instrument_id => @instrument.url_name, :facility_id => @authable.url_name)
    end

    it_should_allow_all facility_users do
      assigns[:facility].should == @authable
      assigns[:instrument].should == @instrument
    end

    context 'schedule rules' do
      before :each do
        sign_in @guest
        @now = Time.zone.now
        @params.merge!(:start => @now.to_i)
      end

      it 'should set end to end of day of start if blank' do
        do_request
        assigns[:end_at].should match_date @now.end_of_day
      end

      it 'should include a reservation from today' do
        @reservation = @instrument.reservations.create(:reserve_start_at => @now, :order_detail => @order_detail,
                                                      :duration_value => 60, :duration_unit => 'minutes')
        do_request
        assigns[:reservations].should =~ [@reservation]
      end

      it 'should not contain reservations from before start date' do
        @reservation = @instrument.reservations.create(:reserve_start_at => @now - 1.day, :order_detail => @order_detail,
                                                      :duration_value => 60, :duration_unit => 'minutes')
        do_request
        assigns[:reservations].should_not include @reservation
      end

      it 'should not contain reservations from after the end date' do
        @reservation = @instrument.reservations.create(:reserve_start_at => @now + 3.days, :order_detail => @order_detail,
                                                      :duration_value => 60, :duration_unit => 'minutes')
        @params.merge!(:end => @now + 2.days)
        do_request
        assigns[:reservations].should_not include @reservation
      end

      it 'should not contain @unavailable if more than a week' do
        @params.merge!(:start => 1.day.ago.to_i, :end => 7.days.from_now.to_i)
        do_request
        assigns[:unavailable].should == []
      end

      context 'schedule rules' do
        before :each do
          @instrument.update_attributes(:requires_approval => true)
          @restriction_level = FactoryGirl.create(:product_access_group, :product_id => @instrument.id)
          @rule.product_access_groups = [@restriction_level]
          @rule.save!
        end

        it 'should not contain rule if not part of group' do
          do_request
          assigns[:rules].should be_empty
        end

        it 'should contain rule if user is part of group' do
          @product_user = ProductUser.create({:product => @instrument, :user => @guest, :approved_by => @director.id, :product_access_group => @restriction_level})
          do_request
          assigns[:rules].should =~ [@rule]
        end

        context 'as admin' do
          before :each do
            maybe_grant_always_sign_in :director
          end
          it 'should contain all schedule rules' do
            do_request
            assigns[:rules].should =~ [@rule]
          end
        end
      end
    end

    describe 'shared scheduling' do
      before :each do
        @instrument2 = FactoryGirl.create(:setup_instrument, :facility => @authable, :schedule => @instrument.schedule)
        @reservation = FactoryGirl.create(:purchased_reservation, :product => @instrument)
        assert @reservation.valid?
        # Second reservation that begins immediately after the first reservation
        @reservation2 = FactoryGirl.create(:purchased_reservation,
                                              :product => @instrument2,
                                              :reserve_start_at => @reservation.reserve_end_at,
                                              :reserve_end_at => @reservation.reserve_end_at + 1.hour)
        assert @reservation2.valid?
        @params.merge!(:start => 1.day.from_now.to_i)
        sign_in @admin
        do_request
      end

      it 'should include reservation from instrument 1' do
        assigns(:reservations).should include @reservation
      end

      it 'should include reservation from instrument 2' do
        assigns(:reservations).should include @reservation2
      end
    end
  end

  context 'list' do
    before :each do
      @method=:get
      @action=:list
      @params = {}
    end


    it "should redirect to default view" do
      maybe_grant_always_sign_in(:staff)
      @params.merge!(:status => 'junk')
      do_request
      should redirect_to "/reservations/upcoming"
    end


    context "upcoming" do
      before :each do
        @params = {:status => 'upcoming'}
      end

      it_should_require_login

      it_should_allow :staff do
        assigns(:available_statuses).size.should == 2
        assigns(:status).should == assigns(:available_statuses).first
        assigns(:order_details).should == (OrderDetail.upcoming_reservations.all + OrderDetail.in_progress_reservations.all)
        expect(assigns(:active_tab)).to eq('reservations')
        should render_template('list')
      end
    end


    context 'all' do
      before :each do
        @params = {:status => 'all'}
      end

      it 'should respond with all reservations' do
        maybe_grant_always_sign_in :staff
        do_request
        assigns(:status).should == 'all'
        assigns(:available_statuses).size.should == 2
        assigns(:order_details).should == OrderDetail.all_reservations.all
        expect(assigns(:active_tab)).to eq('reservations')
        should render_template('list')
      end
    end

  end


  context 'creating a reservation in the past' do
    before :each do
      @method=:post
      @action=:create
      @order            = @guest.orders.create(FactoryGirl.attributes_for(:order, :created_by => @admin.id, :account => @account))
      @order.add(@instrument, 1)
      @order_detail     = @order.order_details.first
      @price_policy_past = @instrument.instrument_price_policies.create!(FactoryGirl.attributes_for(:instrument_price_policy, :price_group_id => @price_group.id, :start_date => 7.days.ago, :expire_date => 1.day.ago, :usage_rate => 2, :reservation_rate => 0))
      @params={
        :order_id => @order.id,
        :order_detail_id => @order_detail.id,
        :order_account => @account.id,
        :reservation => {
            :reserve_start_date => format_usa_date(Time.zone.now.to_date - 5.days),
            :reserve_start_hour => '9',
            :reserve_start_min => '0',
            :reserve_start_meridian => 'am',
            :duration_value => '60',
            :duration_unit => 'minutes'
        }
      }
    end

    it_should_allow_all facility_operators, 'should redirect' do
      assert_redirected_to purchase_order_path(@order)
    end

    it_should_allow_all facility_operators, 'and not have errors' do
      assigns[:reservation].errors.should be_empty
    end

    it_should_allow_all facility_operators, 'to still be new' do
      assigns[:reservation].order_detail.reload.state.should == 'new'
    end

    it_should_allow_all facility_operators, "and isn't a problem" do
      assigns[:reservation].order_detail.reload.should_not be_problem_order
    end

    it_should_allow_all [:guest], 'to receive an error they are trying to reserve in the past' do
      assigns[:reservation].errors.should_not be_empty
      response.should render_template(:new)
    end

    it_should_allow_all facility_operators, 'not set a price policy' do
      assigns[:reservation].order_detail.reload.price_policy.should be_nil
    end

    it_should_allow_all facility_operators, 'set the right estimated price' do
      assigns[:reservation].order_detail.reload.estimated_cost.should == 120
    end

  end

  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(
        :order_account => @account.id,
        :reservation => {
            :reserve_start_date => format_usa_date(Time.zone.now.to_date+1.day),
            :reserve_start_hour => '9',
            :reserve_start_min => '0',
            :reserve_start_meridian => 'am',
            :duration_value => '60',
            :duration_unit => 'minutes'
        }
      )
    end

    it_should_allow_all facility_users, "to create reservation for tomorrow @ 8 am for 60 minutes, set order detail price estimates" do
      assigns[:order].should == @order
      assigns[:order_detail].should == @order_detail
      assigns[:instrument].should == @instrument
      assigns[:reservation].should be_valid
      assigns[:order_detail].estimated_cost.should_not be_nil
      assigns[:order_detail].estimated_subsidy.should_not be_nil
      should set_the_flash
      assert_redirected_to purchase_order_path(@order)
    end

    context 'notifications when acting as' do
      before :each do
        sign_in @admin
        switch_to @guest
      end

      it 'should set the option for sending notifications' do
        @params.merge!(:send_notification => '1')
        do_request
        response.should redirect_to purchase_order_path(@order, :send_notification => '1')
      end

      it 'should set the option for not sending notifications' do
        @params.merge!(:send_notification => '0')
        do_request
        response.should redirect_to purchase_order_path(@order)
      end
    end

    context 'merge order' do
      before :each do
        @merge_to_order=@order.dup
        assert @merge_to_order.save
        assert @order.update_attribute :merge_with_order_id, @merge_to_order.id
      end

      it_should_allow :director, 'to create a reservation on merge order detail and redirect to order summary when merge order is destroyed' do
        assert_redirected_to facility_order_path(@authable, @merge_to_order)
        assert_raises(ActiveRecord::RecordNotFound) { Order.find @order }
      end

      context 'extra order details' do
        before :each do
          @service=@authable.services.create(FactoryGirl.attributes_for(:service, :facility_account_id => @facility_account.id))
          Service.any_instance.stub(:active_survey?).and_return(true)
          @service_order_detail=@order.order_details.create(FactoryGirl.attributes_for(:order_detail, :product_id => @service.id, :account_id => @account.id))
        end

        it_should_allow :director, 'to create a reservation on merge order detail and redirect to order summary when merge order is not destroyed' do
          assert_redirected_to facility_order_path(@authable, @merge_to_order)
          assert_nothing_raised { Order.find @order }
        end
      end

      context 'creating a reservation in the past' do
        before :each do
          @params.deep_merge!(:reservation => {:reserve_start_date => 1.day.ago})
        end

        it_should_allow_all facility_operators, 'to create a reservation in the past and have it be complete' do
          assigns(:reservation).errors.should be_empty
          assigns(:order_detail).state.should == 'complete'
          response.should redirect_to facility_order_path(@authable, @merge_to_order)
        end

        context 'and there is no price policy' do
          before :each do
            @price_policy.update_attributes(:expire_date => 2.days.ago)
          end

          it_should_allow_all facility_operators, 'to create the reservation, but have it be a problem order' do
            assigns(:order_detail).state.should == 'complete'
            assigns(:order_detail).should be_problem_order
          end
        end
      end

      context 'creating a reservation in the future' do
        before :each do
          @params.deep_merge!(:reservation => {:reserve_start_date => 1.day.from_now})
        end

        it_should_allow_all facility_operators, 'to create a reservation in the future' do
          assigns(:reservation).errors.should be_empty
          assigns(:order_detail).state.should == 'new'
          response.should redirect_to facility_order_path(@authable, @merge_to_order)
        end
      end
    end

    context 'creating a reservation in the future' do
      before :each do
        @params.deep_merge!(:reservation => {:reserve_start_date => Time.zone.now.to_date + (PriceGroupProduct::DEFAULT_RESERVATION_WINDOW + 1).days })
      end
      it_should_allow_all facility_operators, "to create a reservation beyond the default reservation window" do
        assert_redirected_to purchase_order_path(@order)
      end
      it_should_allow_all [:guest], "to receive an error that they are trying to reserve outside of the window" do
        assigns[:reservation].errors.should_not be_empty
        response.should render_template(:new)
      end
    end

    context 'creating a reservation in the future with no price policy' do
      before :each do
        @params[:reservation][:reserve_start_date] = format_usa_date(@price_policy.expire_date+1.day)
        @price_group_product.update_attributes(:reservation_window => 365)
        sign_in @guest
        do_request
      end
      it 'should allow creation' do
        assigns[:reservation].should_not be_nil
        assigns[:reservation].should_not be_new_record
      end
    end

    context 'without account' do
      before :each do
        @params.delete :order_account
        sign_in @guest
        do_request
      end
      it 'should have a flash message and render :new' do
        flash[:error].should be_present
        response.should render_template :new
      end
      it 'should maintain duration value and units' do
        assigns[:reservation].duration_value.should == 60
        assigns[:reservation].duration_unit.should == "minutes"
      end
      it 'should not lose the time' do
        assigns[:reservation].reserve_start_date.should == format_usa_date(Time.zone.now.to_date+1.day)
        assigns[:reservation].reserve_start_hour.should == 9
        assigns[:reservation].reserve_start_min.should == 0
        assigns[:reservation].reserve_start_meridian.should == 'am'
      end
      it 'should assign the correct variables' do
        assigns[:order].should == @order
        assigns[:order_detail].should == @order_detail
        assigns[:instrument].should == @instrument
        flash[:error].should be_present
        should render_template :new
      end
    end

    context 'with new account' do

      before :each do
        @account2=FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @guest))
        define_open_account(@instrument.account, @account2.account_number)
        @params.merge!({ :order_account => @account2.id })
        @order.account.should == @account
        @order_detail.account.should == @account
      end

      it_should_allow :guest do
        @order.reload.account.should == @account2
        @order.order_details.first.account.should == @account2
        @order_detail.reload.account.should == @account2
      end
    end

    context 'with a price policy attached to the account' do
      before :each do
        @order.update_attributes(:account => nil)
        @order.account.should be_nil
        @order_detail.account.should be_nil

        @price_group2      = @authable.price_groups.create(FactoryGirl.attributes_for(:price_group))
        @pg_account        = FactoryGirl.create(:account_price_group_member, :account => @account, :price_group => @price_group2)
        @price_policy2     = @instrument.instrument_price_policies.create!(FactoryGirl.attributes_for(:instrument_price_policy, :price_group_id => @price_group2.id, :usage_rate => 1, :usage_subsidy => 0.25))
        sign_in @guest
      end
      it "should use the policy based on the account because it's cheaper" do
        do_request
        assigns[:order_detail].estimated_cost.should == 120.0
        assigns[:order_detail].estimated_subsidy.should == 15
      end
    end


    context 'with other things in the cart (bundle or multi-add)' do

      before :each do
        @order.add(@instrument, 1)
      end

      it_should_allow :staff, 'but should redirect to cart' do
        assigns[:order].should == @order
        assigns[:order_detail].should == @order_detail
        assigns[:instrument].should == @instrument
        assigns[:reservation].should be_valid
        assigns[:order_detail].estimated_cost.should_not be_nil
        assigns[:order_detail].estimated_subsidy.should_not be_nil
        should set_the_flash
        assert_redirected_to cart_path
      end
    end

  end


  context 'new' do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_all facility_users do
      assigns[:order].should == @order
      assigns[:order_detail].should == @order_detail
      assigns[:instrument].should == @instrument
      expect(assigns(:reservation)).to be_kind_of Reservation
      expect(assigns(:max_window)).to be_kind_of Integer

      assigns[:max_date].should == (Time.zone.now+assigns[:max_window].days).strftime("%Y%m%d")
    end

    # Managers should be able to go far out into the future
    it_should_allow_all facility_operators do
      assigns[:max_window].should == 365
      assigns[:max_days_ago].should == -365
      assigns[:min_date].should == (Time.zone.now+assigns[:max_days_ago].days).strftime("%Y%m%d")
      assigns[:max_date].should == (Time.zone.now + 365.days).strftime("%Y%m%d")
    end
    # guests should only be able to go the default reservation window into the future
    it_should_allow_all [:guest] do
      assigns[:max_window].should == PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
      assigns[:max_days_ago].should == 0
      assigns[:max_date].should == (Time.zone.now + PriceGroupProduct::DEFAULT_RESERVATION_WINDOW.days).strftime("%Y%m%d")
      assigns[:min_date].should == Time.zone.now.strftime("%Y%m%d")
    end

    context 'a user with no price groups' do
      before :each do
        sign_in @guest
        User.any_instance.stub(:price_groups).and_return([])
        @order_detail.update_attributes(:account => nil)
        # Only worry about one price group product
        @instrument.price_group_products.destroy_all
        pgp  = FactoryGirl.create(:price_group_product, :product => @instrument, :price_group => FactoryGirl.create(:price_group, :facility => @authable), :reservation_window => 14)
      end

      it "does not have an account on the order detail" do
        do_request
        assigns(:order_detail).account.should be_nil
      end

      it 'is a successful page render' do
        do_request
        response.should be_success
      end

      it "uses the minimum reservation window" do
        pgp2 = FactoryGirl.create(:price_group_product, :product => @instrument, :price_group => FactoryGirl.create(:price_group, :facility => @authable), :reservation_window => 7)
        pgp3 = FactoryGirl.create(:price_group_product, :product => @instrument, :price_group => FactoryGirl.create(:price_group, :facility => @authable), :reservation_window => 21)
        do_request
        assigns(:max_window).should == 7
      end
    end

  end


  context 'needs future reservation' do

    before :each do
      # create reservation for tomorrow @ 9 am for 60 minutes, with order detail reference
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation  = @instrument.reservations.create(:reserve_start_at => @start, :order_detail => @order_detail,
                                                      :duration_value => 60, :duration_unit => 'minutes')
      assert @reservation.valid?
    end


    context 'show' do

      before :each do
        @method=:get
        @action=:show
        @params.merge!(:id => @reservation.id)
      end

      it_should_allow_all facility_users do
        assigns[:reservation].should == @reservation
        assigns[:order_detail].should == @reservation.order_detail
        assigns[:order].should == @reservation.order_detail.order
        should respond_with :success
      end

    end


    context 'edit' do

      before :each do
        @method=:get
        @action=:edit
        @params.merge!(:id => @reservation.id)
      end

      it_should_allow_all facility_users do
        assigns[:reservation].should == @reservation
        assigns[:order_detail].should == @reservation.order_detail
        assigns[:order].should == @reservation.order_detail.order
        should respond_with :success
      end

      it "should throw 404 if reservation is cancelled" do
        @reservation.update_attributes(:canceled_at => Time.zone.now - 1.day)
        sign_in @admin
        do_request
        response.response_code.should == 404
      end

      it "should throw 404 if reservation happened" do
        @reservation.update_attributes(:actual_start_at => Time.zone.now - 1.day)
        sign_in @admin
        do_request
        response.response_code.should == 404
      end

    end


    context 'update' do

      before :each do
        @method=:put
        @action=:update
        @params.merge!(
          :id => @reservation.id,
          :reservation => {
            :reserve_start_date => @start.to_date,
            :reserve_start_hour => '10',
            :reserve_start_min => '0',
            :reserve_start_meridian => 'am',
            :duration_value => '60',
            :duration_unit => 'minutes'
          }
        )
      end

      it_should_allow_all facility_users, "to update reservation" do
        assigns[:order].should == @order
        assigns[:order_detail].should == @order_detail
        assigns[:instrument].should == @instrument
        assigns[:reservation].should be_valid
        assigns[:reservation].should_not be_changed
        # should update reservation time
        @reservation.reload.reserve_start_hour.should == 10
        @reservation.reserve_end_hour.should == 11
        @reservation.duration_mins.should == 60
        assigns[:order_detail].estimated_cost.should_not be_nil
        assigns[:order_detail].estimated_subsidy.should_not be_nil
        should set_the_flash
        assert_redirected_to cart_url
      end

      context 'creating a reservation in the future' do
        before :each do
          @params.deep_merge!(:reservation => {:reserve_start_date => Time.zone.now.to_date + (PriceGroupProduct::DEFAULT_RESERVATION_WINDOW + 1).days })
        end
        it_should_allow_all facility_operators, "to create a reservation beyond the default reservation window" do
          assigns[:reservation].errors.should be_empty
          assert_redirected_to cart_url
        end
        it_should_allow_all [:guest], "to receive an error that they are trying to reserve outside of the window" do
          assigns[:reservation].errors.should_not be_empty
          response.should render_template(:edit)
        end
      end

    end

  end

  context 'earliest move possible' do
    before :each do
      @method = :get
      @action = :earliest_move_possible

      maybe_grant_always_sign_in :guest
    end

    context 'valid short reservation' do
      before :each do
        @reservation = @instrument.reservations.create(
          :reserve_start_at => Time.zone.now+1.day,
          :order_detail     => @order_detail,
          :duration_value   => 60,
          :duration_unit    => 'minutes'
        )

        @params.merge!(:reservation_id => @reservation.id)
        do_request
      end

      it 'should get earliest move possible' do
        response.code.should == "200"
        response.headers['Content-Type'].should == 'text/html; charset=utf-8'
        response.should render_template 'reservations/earliest_move_possible'
        response.body.to_s.should =~ /The earliest time you can move this reservation to begins on [^<>]+ at [^<>]+ and ends at [^<>]+./
      end
    end

    context 'valid long reservation' do
      before :each do
        # remove all scheduling rules/constraints to allow for the creation of a long reservation
        @instrument.schedule_rules.destroy_all
        @instrument.update_attributes :max_reserve_mins => nil
        FactoryGirl.create(:all_day_schedule_rule, :instrument => @instrument)

        @reservation = @instrument.reservations.create!(
          :reserve_start_at => Time.zone.now+1.day,
          :order_detail     => @order_detail,
          :duration_value   => 24,
          :duration_unit    => 'hours'
        )

        @params.merge!(:reservation_id => @reservation.id)
        do_request
      end

      it 'should get earliest move possible' do
        response.code.should == "200"
        response.headers['Content-Type'].should == 'text/html; charset=utf-8'
        response.should render_template 'reservations/earliest_move_possible'
        response.body.to_s.should =~ /The earliest time you can move this reservation to begins on [^<>]+ at [^<>]+ and ends on [^<>]+ at [^<>]+./
      end
    end

    context 'invalid reservation' do
      before :each do
        @params.merge!(:reservation_id => 999)
        do_request
      end

      it 'should return a 404' do
        response.code.should == "404"
      end
    end
  end


  context 'move' do
    before :each do
      @method=:post
      @action=:move
      @reservation  = @instrument.reservations.create(:reserve_start_at => Time.zone.now+1.day, :order_detail => @order_detail,
                                                      :duration_value => 60, :duration_unit => 'minutes')
      @earliest=@reservation.earliest_possible
      @reservation.reserve_start_at.should_not == @earliest.reserve_start_at
      @reservation.reserve_end_at.should_not == @earliest.reserve_end_at
      @params.merge!(:reservation_id => @reservation.id)
    end

    it_should_allow :guest, 'to move a reservation' do
      assigns(:order).should == @order
      assigns(:order_detail).should == @order_detail
      assigns(:instrument).should == @instrument
      assigns(:reservation).should == @reservation
      human_datetime(assigns(:reservation).reserve_start_at).should == human_datetime(@earliest.reserve_start_at)
      human_datetime(assigns(:reservation).reserve_end_at).should == human_datetime(@earliest.reserve_end_at)
      should set_the_flash
      assert_redirected_to reservations_status_path(:status => 'upcoming')
    end
  end

  context 'needs now reservation' do

    before :each do
      # create reservation for tomorrow @ 9 am for 60 minutes, with order detail reference
      @start        = Time.zone.now + 1.second
      @reservation  = @instrument.reservations.create(:reserve_start_at => @start, :order_detail => @order_detail,
                                                      :duration_value => 60, :duration_unit => 'minutes')
      assert @reservation.valid?
    end

    context 'move' do
      before :each do
        @method=:post
        @action=:move
        @reservation.earliest_possible.should be_nil
        @orig_start_at=@reservation.reserve_start_at
        @orig_end_at=@reservation.reserve_end_at
        @params.merge!(:reservation_id => @reservation.id)
      end

      it_should_allow :guest, 'but not move the reservation' do
        assigns(:order).should == @order
        assigns(:order_detail).should == @order_detail
        assigns(:instrument).should == @instrument
        assigns(:reservation).should == @reservation
        human_datetime(assigns(:reservation).reserve_start_at).should == human_datetime(@orig_start_at)
        human_datetime(assigns(:reservation).reserve_end_at).should == human_datetime(@orig_end_at)
        should set_the_flash
        assert_redirected_to reservations_status_path(:status => 'upcoming')
      end
    end

    context 'switch_instrument' do

      before :each do
        @method=:get
        @action=:switch_instrument
        @params.merge!(:reservation_id => @reservation.id)
        FactoryGirl.create(:relay, :instrument => @instrument)
        @random_user = FactoryGirl.create(:user)
      end

      context 'on' do
         before :each do
           @params.merge!(:switch => 'on')
         end

        it_should_allow :guest do
          assigns(:order).should == @order
          assigns(:order_detail).should == @order_detail
          assigns(:instrument).should == @instrument
          assigns(:reservation).should == @reservation
          assigns(:reservation).actual_start_at.should < Time.zone.now
          assigns(:instrument).instrument_statuses.size.should == 1
          assigns(:instrument).instrument_statuses[0].is_on.should == true
          should set_the_flash
          should respond_with :redirect
        end

        it_should_allow_all facility_operators, 'turn on instrument from someone elses reservation' do
          should respond_with :redirect
        end
        it_should_deny :random_user

      end

      context 'off' do
         before :each do
           @reservation.update_attribute(:actual_start_at, @start)
           @params.merge!(:switch => 'off')
           sleep 2 # because res start time is now + 1 second. Need to make time validations pass.
           @reservation.order_detail.price_policy.should be_nil
         end

        it_should_allow :guest do
          assigns(:order).should == @order
          assigns(:order_detail).should == @order_detail
          assigns(:instrument).should == @instrument
          assigns(:reservation).should == @reservation
          assigns(:reservation).order_detail.price_policy.should_not be_nil
          assigns(:reservation).actual_end_at.should < Time.zone.now
          assigns(:instrument).instrument_statuses.size.should == 1
          assigns(:instrument).instrument_statuses[0].is_on.should == false
          should set_the_flash
          should respond_with :redirect
        end

        it_should_allow_all facility_operators, 'turn off instrument from someone elses reservation' do
          should respond_with :redirect
        end
        it_should_deny :random_user

        context "for instrument w/ accessory" do
          before :each do
            ## (setup stolen from orders_controller_spec)
            ## create a purchasable item
            @item = @authable.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
            @item_pp=@item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id))
            @item_pp.reload.restrict_purchase=false

            ## make it an accessory of the reserved product
            @instrument.product_accessories.create!(:accessory => @item)
          end

          it_should_allow :guest, "it redirects to the accessories" do
            should redirect_to new_order_order_detail_accessory_path(@order, @order_detail)
          end
        end
      end
    end
  end
end
