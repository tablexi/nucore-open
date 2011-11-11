require 'spec_helper'; require 'controller_spec_helper'

describe ReservationsController do
  include DateHelper

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @account          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @guest, :created_by => @guest, :user_role => 'Owner']])
    @price_group      = @authable.price_groups.create(Factory.attributes_for(:price_group))
    @pg_member        = Factory.create(:user_price_group_member, :user => @guest, :price_group => @price_group)
    # create instrument, min reserve time is 60 minutes, max is 60 minutes
    @options          = Factory.attributes_for(:instrument, :facility_account => @facility_account,
                                               :min_reserve_mins => 60, :max_reserve_mins => 60, :relay_ip => '192.168.1.1')
    @instrument       = @authable.instruments.create(@options)
    assert @instrument.valid?
    Factory.create(:price_group_product, :product => @instrument, :price_group => @price_group)
    # add rule, available every day from 9 to 5, 60 minutes duration
    @rule             = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :end_hour => 23))
    # create price policy with default window of 1 day
    @price_policy     = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id))
    # create order, order detail
    @order            = @guest.orders.create(Factory.attributes_for(:order, :created_by => @guest.id, :account => @account))
    @order.add(@instrument, 1)
    @order_detail     = @order.order_details.first
    @params={ :order_id => @order.id, :order_detail_id => @order_detail.id }
  end



  context 'index' do

    before :each do
      @method=:get
      @action=:index
      @params.merge!(:instrument_id => @instrument.url_name, :facility_id => @authable.url_name)
    end

    it_should_allow_all facility_users do
      assigns[:facility].should == @authable
      assigns[:instrument].should == @instrument
    end

    it 'should test more than auth'

  end

  context 'list' do
    before :each do
      @method=:get
      @action=:list
    end

    it_should_require_login

    it_should_allow :staff do
      should respond_with :success
      should assign_to(:order_details).with_kind_of(Array)
      should assign_to(:active_tab).with('reservations')
      should render_template('list')
    end
  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(
        :reservation => {
            :reserve_start_date => Time.zone.now.to_date+1.day,
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

    context 'with new account' do

      before :each do
        @account2=Factory.create(:nufs_account, :account_users_attributes => [{:user => @guest, :created_by => @guest, :user_role => 'Owner'}])
        define_open_account(@instrument.account, @account2.account_number)
        @params.merge!({ :order_account => @account2.id })
        @order.account.should == @account
        @order_detail.account.should == @account
      end

      it_should_allow :guest do
        @order.reload.account.should == @account2
        @order_detail.reload.account.should == @account2
      end

    end

    context 'as bundle' do

      before :each do
        bundle=Factory.create(:bundle, :facility_account => @facility_account, :facility => @authable)
        @order_detail.update_attribute(:bundle_product_id, bundle.id)
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
      should assign_to(:reservation).with_kind_of Reservation
      should assign_to(:max_window).with_kind_of Integer
      assigns[:min_date].should == Time.zone.now.strftime("%Y%m%d")
      assigns[:max_date].should == (Time.zone.now+assigns[:max_window].days).strftime("%Y%m%d")
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
        should respond_with :success
      end

      it 'should test more than auth'

    end


    context 'edit' do

      before :each do
        @method=:get
        @action=:edit
        @params.merge!(:id => @reservation.id)
      end

      it_should_allow_all facility_users do
        should respond_with :success
      end

      it 'should test more than auth'

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
        # should update reservation time
        @reservation.reload.reserve_start_hour.should == 10
        @reservation.reserve_end_hour.should == 11
        @reservation.duration_mins.should == 60
        assigns[:order_detail].estimated_cost.should_not be_nil
        assigns[:order_detail].estimated_subsidy.should_not be_nil
        should set_the_flash
        assert_redirected_to cart_url
      end

    end

  end


  context 'move' do
    before :each do
      @method=:get
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
      assert_redirected_to reservations_path
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
        @method=:get
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
        assert_redirected_to reservations_path
      end
    end

    context 'switch_instrument' do

      before :each do
        @method=:get
        @action=:switch_instrument
        @params.merge!(:reservation_id => @reservation.id)
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
      end

    end
  end

end
