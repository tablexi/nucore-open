require "rails_helper"
require 'controller_spec_helper'

RSpec.describe FacilityReservationsController do
  include DateHelper

  let(:account) { @account }
  let(:facility) { @authable }
  let(:product) { @product }
  let(:schedule_rule) { @schedule_rule }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @facility_account=FactoryGirl.create(:facility_account, :facility => @authable)
    @product=FactoryGirl.create(:instrument,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @schedule_rule=FactoryGirl.create(:schedule_rule, :instrument => @product)
    @product.reload
    @account = create_nufs_account_with_owner :director
    @order=FactoryGirl.create(:order,
      :facility => @authable,
      :user => @director,
      :created_by => @director.id,
      :account => @account,
      :ordered_at => Time.zone.now,
      :state => 'purchased'
    )

    @reservation=FactoryGirl.create(:reservation, :product => @product)
    expect(@reservation).not_to be_new_record
    @order_detail = create(:order_detail, account: account, order: @order, product: product, reservation: @reservation)
    @order_detail.set_default_status!
    @params={ :facility_id => @authable.url_name, :order_id => @order.id, :order_detail_id => @order_detail.id, :id => @reservation.id }
  end

  context '#assign_price_policies_to_problem_orders' do
    let(:order_details) { [ @order_detail ] }
    let(:order_detail_ids) { order_details.map(&:id) }

    before :each do
      @method = :post
      @action = :assign_price_policies_to_problem_orders

      start_time = 1.week.ago + schedule_rule.start_hour
      end_time = start_time + 1.hour

      order_details.each do |order_detail|
        order_detail.reservation.update_attributes(
          reserve_start_at: start_time,
          reserve_end_at: end_time,
          actual_start_at: start_time,
          actual_end_at: end_time,
        )
        order_detail.backdate_to_complete!
      end
    end

    context 'when compatible price policies exist' do
      let(:price_group) { create(:price_group, facility: facility) }

      before :each do
        create(:account_price_group_member, account: account, price_group: price_group)

        order_details.first.product.instrument_price_policies.create(attributes_for(
          :instrument_price_policy, price_group_id: price_group.id))

        do_request
      end

      it_should_allow_operators_only :redirect do
        expect(OrderDetail.where(id: order_detail_ids, problem: false).count)
        .to eq order_details.count
      end
    end

    context 'when no compatible price policies exist' do
      before :each do
        InstrumentPricePolicy.all.each(&:destroy)
        do_request
      end

      it_should_allow_operators_only :redirect do
        expect(OrderDetail.where(id: order_detail_ids, problem: true).count)
        .to eq order_details.count
      end
    end
  end

  context '#batch_update' do
    before :each do
      @method = :post
      @action = :batch_update
    end

    it_should_allow_operators_only :redirect
  end

  context '#create' do
    before :each do
      @method=:post
      @action=:create
      @time = 1.hour.from_now.change(:sec => 0)
      @params={
        :facility_id => @authable.url_name,
        :instrument_id => @product.url_name,
        :reservation => FactoryGirl.attributes_for(:reservation, :reserve_start_at => @time, :reserve_end_at => @time + 1.hour)
      }
      parametrize_dates(@params[:reservation], :reserve)
    end

    it_should_allow_operators_only(:redirect) {}

    context 'while signed in' do
      before :each do
        maybe_grant_always_sign_in :director
      end
      context 'a success' do
        before(:each) { do_request }
        it 'should create the reservation' do
          expect(assigns[:reservation]).not_to be_nil
          expect(assigns[:reservation]).not_to be_new_record
        end
        it 'should be an admin reservation' do
          expect(assigns[:reservation]).to be_admin
        end
        it 'should set the times' do
          expect(assigns[:reservation].reserve_start_at).to eq(@time)
          expect(assigns[:reservation].reserve_end_at).to eq(@time + 1.hour)
        end
        it "should redirect to the facility's schedule page" do
          expect(response).to redirect_to facility_instrument_schedule_path
        end
      end

      context 'fails validations' do

        it 'should not allow an invalid reservation' do
          # Used to fail by overlapping existing reservation, but now admin reservations are
          # allowed to per ticket 38975
          allow_any_instance_of(Reservation).to receive(:valid?).and_return(false)
          @params[:reservation] = FactoryGirl.attributes_for(:reservation)
          parametrize_dates(@params[:reservation], :reserve)
          do_request
          expect(assigns[:reservation]).to be_new_record
          expect(response).to render_template :new
        end
      end
    end
  end

  context '#disputed' do
    before(:each) do
      @method = :get
      @action = :disputed
    end

    it_should_allow_managers_only # TODO: identical to FacilityOrdersController#disputed spec
  end

  context '#edit' do
    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_operators_only do
      expect(assigns(:order)).to eq(@order)
      expect(assigns(:order_detail)).to eq(@order_detail)
      expect(assigns(:reservation)).to eq(@reservation)
      expect(assigns(:instrument)).to eq(@product)
      is_expected.to render_template 'edit'
    end

    context 'redirect on no edit' do
      before :each do
        @reservation.update_attribute(:canceled_at, Time.zone.now)
      end

      it_should_allow :director do
        assert_redirected_to facility_order_order_detail_reservation_path(@authable, @order, @order_detail, @reservation)
      end
    end
  end

  context '#index' do
    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_operators_only {}

    context "once signed in" do
      before :each do
        sign_in(@admin)
      end

      it 'should not return non-reservation order details' do
        # setup_reservation overwrites @order_detail
        @order_detail_reservation = @order_detail

        @product=FactoryGirl.create(:item, :facility_account => @facility_account, :facility => @authable)
        @order_detail_item = place_product_order(@director, @authable, @product, @account)
        @order_detail.order.update_attributes!(:state => 'purchased')

        expect(@authable.reload.order_details).to contain_all [@order_detail_reservation, @order_detail_item]
        do_request
        expect(assigns[:order_details]).to eq([@order_detail_reservation])
      end

      it "provides sort headers that don't result in errors"
    end
  end

  context '#new' do
    before :each do
      @method=:get
      @action=:new
      @params={ :facility_id => @authable.url_name, :instrument_id => @product.url_name }
    end

    it_should_allow_operators_only
  end

  context '#show' do
    before :each do
      @method=:get
      @action=:show
    end

    it_should_allow_operators_only
  end

  context '#show_problems' do
    skip "TODO test exists for the FacilityOrdersController version"
  end

  context '#timeline' do
    context 'instrument listing' do
      before :each do
        @instrument2 = FactoryGirl.create(:instrument,
                      facility_account: @facility_account,
                      facility: @authable,
                      is_hidden: true)
        maybe_grant_always_sign_in :director
        @method = :get
        @action = :timeline
        @params = { facility_id: @authable.url_name }
      end

      it 'should show schedules for hidden instruments' do
        do_request
        expect(assigns(:schedules)).to match_array([@product.schedule, @instrument2.schedule])
      end

      it "defaults the display date to today" do
        do_request
        expect(assigns[:display_datetime]).to eq(Time.current.beginning_of_day)
      end

      it "parses the date" do
        @params.merge!(date: "6/14/2015")
        do_request
        expect(assigns[:display_datetime]).to eq(Time.zone.parse("2015-06-14T00:00"))
      end
    end

    context 'orders' do
      before :each do
        # create unpurchased reservation
        @order2=FactoryGirl.create(:order,
        :facility => @authable,
        :user => @director,
        :created_by => @director.id,
        :account => @account,
        :ordered_at => nil,
        :state => 'new'
        )
        # make sure the reservations are happening today
        @reservation.update_attributes!(:reserve_start_at => Time.zone.now, :reserve_end_at => 1.hour.from_now)

        @unpurchased_reservation=FactoryGirl.create(:reservation, :product => @product, :reserve_start_at => 1.hour.from_now, :reserve_end_at => 2.hours.from_now)
        @order_detail2=FactoryGirl.create(:order_detail, :order => @order2, :product => @product, :reservation => @unpurchased_reservation)

        @canceled_reservation = FactoryGirl.create(:reservation, :product => @product, :reserve_start_at => 2.hours.from_now, :reserve_end_at => 3.hours.from_now)
        @order_detail3 = FactoryGirl.create(:order_detail, :order => @order, :product => @product, :reservation => @canceled_reservation)
        expect(@canceled_reservation).to be_persisted
        @order_detail3.update_order_status! @admin, OrderStatus.canceled.first

        @admin_reservation = FactoryGirl.create(:reservation, :product => @product, :reserve_start_at => Time.zone.now, :reserve_end_at => 1.hour.from_now)

        maybe_grant_always_sign_in :director
        @method = :get
        @action = :timeline
        @params={ :facility_id => @authable.url_name }
        do_request
      end

      it 'should not be admin reservations' do
        expect(@reservation).not_to be_admin
        expect(@unpurchased_reservation).not_to be_admin
        expect(@admin_reservation).to be_admin
      end

      it 'should show reservation' do
        expect(response.body).to include "id='tooltip_reservation_#{@reservation.id}'"
      end

      it 'should not show unpaid reservation' do
        expect(response.body).not_to include "id='tooltip_reservation_#{@unpurchased_reservation.id}'"
      end

      it 'should include canceled reservation' do
        expect(response.body).to include "id='tooltip_reservation_#{@canceled_reservation.id}'"
      end

      it 'should include admin reservation' do
        expect(response.body).to include "id='tooltip_reservation_#{@admin_reservation.id}'"
      end
    end
  end

  context '#update' do
    before :each do
      @method=:put
      @action=:update
      @params.merge!(:reservation => FactoryGirl.attributes_for(:reservation))
    end


    it_should_allow_operators_only do
      expect(assigns(:order)).to eq(@order)
      expect(assigns(:order_detail)).to eq(@order_detail)
      expect(assigns(:reservation)).to eq(@reservation)
      expect(assigns(:instrument)).to eq(@product)
    end

    context "updating reservation length before complete" do
      before :each do
        expect(@order_detail.price_policy).to be_nil
        @order_detail.account = @account
        @order_detail.save!
        @price_group=FactoryGirl.create(:price_group, :facility => @authable)
        create(:account_price_group_member, account: account, price_group: @price_group)
        @instrument_pp=@product.instrument_price_policies.create(FactoryGirl.attributes_for(:instrument_price_policy, :price_group_id => @price_group.id))
        @instrument_pp.reload.restrict_purchase=false
        @reservation.update_attributes(:actual_start_at => nil, :actual_end_at => nil)
        @params.merge!(:reservation => {
                :reserve_start_at => @reservation.reserve_start_at,
                :reserve_end_at => @reservation.reserve_end_at - 15.minutes
              }
            )
      end

      it "should update estimated cost" do
        maybe_grant_always_sign_in :director
        do_request
        # In rails 3.1, assigning the same value is still triggering
        # attr_will_change! so this breaks:
        # assigns[:reservation].should_not be_reserve_start_at_changed
        expect(assigns[:reservation].reserve_start_at).to eq(assigns[:reservation].reserve_start_at_was)
        expect(assigns[:reservation]).to be_reserve_end_at_changed
        expect(assigns[:order_detail]).to be_estimated_cost_changed
      end
    end

    context 'completed order' do
      before :each do
        expect(@order_detail.price_policy).to be_nil
        @price_group=FactoryGirl.create(:price_group, :facility => @authable)
        create(:account_price_group_member, account: account, price_group: @price_group)
        @instrument_pp=create(:instrument_price_policy, :product => @product, :price_group_id => @price_group.id, :usage_rate => 2)
        @instrument_pp.reload.restrict_purchase=false
        @now=@reservation.reserve_start_at+3.hour
        maybe_grant_always_sign_in :director
        Timecop.freeze(@now) { @order_detail.to_complete! }
      end

      context 'update actuals' do
        before :each do
          @reservation.update_attributes(:actual_start_at => nil, :actual_end_at => nil)
          @reservation_attrs=FactoryGirl.attributes_for(
              :reservation,
              :actual_start_at => @now-2.hour,
              :actual_end_at => @now-1.hour
          )
          @params.merge!(:reservation => @reservation_attrs)
        end

        it 'should update the actuals and assign a price policy if there is none' do
          Timecop.freeze(@now) do
            do_request
            expect(assigns(:order)).to eq(@order)
            expect(assigns(:order_detail)).to eq(@order_detail)
            expect(assigns(:reservation)).to eq(@reservation)
            expect(assigns(:instrument)).to eq(@product)
            expect(assigns(:reservation).actual_start_at).to eq(@reservation_attrs[:actual_start_at])
            expect(assigns(:reservation).actual_end_at).to eq(@reservation_attrs[:actual_end_at])
            expect(assigns(:order_detail).price_policy).to eq(@instrument_pp)
            expect(assigns(:order_detail).actual_cost).not_to be_nil
            expect(assigns(:order_detail).actual_subsidy).not_to be_nil
            expect(flash[:notice]).to be_present
            is_expected.to render_template 'edit'
          end
        end
      end

      context 'update reserve' do
        before :each do
          @reservation.update_attributes(:actual_start_at => @reservation.reserve_start_at, :actual_end_at => @reservation.reserve_end_at)
          @reservation_attrs=FactoryGirl.attributes_for(
              :reservation,
              :reserve_start_at => @now-3.hour,
              :reserve_end_at   => @now-1.hour,
              :actual_start_at  => @reservation.reserve_start_at,
              :actual_end_at    => @reservation.reserve_end_at
          )
          @params[:reservation] = @reservation_attrs
        end

        it 'should update the actual cost' do
          Timecop.freeze(@now) do
            do_request
            expect(assigns(:reservation).actual_start_at).to  eq(@reservation_attrs[:actual_start_at])
            expect(assigns(:reservation).actual_end_at).to    eq(@reservation_attrs[:actual_end_at])
            expect(assigns(:order_detail).price_policy).to    eq(@instrument_pp)
            expect(assigns(:order_detail).actual_cost).not_to eq(@order_detail.actual_cost)
            expect(flash[:notice]).to be_present
            is_expected.to render_template 'edit'
          end
        end
      end
    end
  end

  describe "#tab_counts" do
    before(:each) do
      @method = :get
      @action = :tab_counts
      @params.merge!(tabs: %w(new_or_in_process_orders disputed_orders problem_order_details))
    end

    it_should_allow_operators_only
    # TODO: more complete tests exist for the FacilityOrdersController version
  end

  context 'admin' do
    before :each do
      @reservation.order_detail_id=nil
      @reservation.save
      @reservation.reload
      @params={ :facility_id => @authable.url_name, :instrument_id => @product.url_name, :reservation_id => @reservation.id }
    end

    context '#edit_admin' do
      before :each do
        @method=:get
        @action=:edit_admin
      end

      it_should_allow_operators_only
    end

    context '#update_admin' do
      before :each do
        @method=:put
        @action=:update_admin
        @params.merge!(:reservation => FactoryGirl.attributes_for(:reservation))
      end

      it_should_allow_operators_only :redirect
    end
  end
end
