require 'spec_helper'; require 'controller_spec_helper'

describe FacilityReservationsController do
  include DateHelper

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @product=Factory.create(:instrument,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @schedule_rule=Factory.create(:schedule_rule, :instrument => @product)
    @product.reload
    @account=create_nufs_account_with_owner
    @order=Factory.create(:order,
      :facility => @authable,
      :user => @director,
      :created_by => @director.id,
      :account => @account,
      :ordered_at => Time.zone.now,
      :state => 'purchased'
    )
    @reservation=Factory.create(:reservation, :instrument => @product)
    @reservation.should_not be_new_record
    @order_detail=Factory.create(:order_detail, :order => @order, :product => @product, :reservation => @reservation)
    @order_detail.set_default_status!
    @params={ :facility_id => @authable.url_name, :order_id => @order.id, :order_detail_id => @order_detail.id, :id => @reservation.id }
  end


  context 'edit' do

    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_operators_only do
      assigns(:order).should == @order
      assigns(:order_detail).should == @order_detail
      assigns(:reservation).should == @reservation
      assigns(:instrument).should == @product
      should render_template 'edit'
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

  context 'index' do
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
        
        @product=Factory.create(:item, :facility_account => @facility_account, :facility => @authable)
        @order_detail_item = place_product_order(@director, @authable, @product, @account)
        @order_detail.order.update_attributes!(:state => 'purchased')   

        @authable.reload.order_details.should contain_all [@order_detail_reservation, @order_detail_item]     
        do_request
        assigns[:order_details].should == [@order_detail_reservation]
      end
      
      it "provides sort headers that don't result in errors"
    end
  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
      @params.merge!(:reservation => Factory.attributes_for(:reservation))
    end


    it_should_allow_operators_only do
      assigns(:order).should == @order
      assigns(:order_detail).should == @order_detail
      assigns(:reservation).should == @reservation
      assigns(:instrument).should == @product
    end

    context "updating reservation length before complete" do
      before :each do
        @order_detail.price_policy.should be_nil
        @order_detail.account = @account
        @order_detail.save!
        @price_group=Factory.create(:price_group, :facility => @authable)
        Factory.create(:user_price_group_member, :user => @director, :price_group => @price_group)
        @instrument_pp=@product.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :price_group_id => @price_group.id))
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
        assigns[:reservation].should_not be_reserve_start_at_changed
        assigns[:reservation].should be_reserve_end_at_changed
        assigns[:order_detail].should be_estimated_cost_changed
      end
    end


    context 'update actuals' do

      before :each do
        @order_detail.price_policy.should be_nil
        @price_group=Factory.create(:price_group, :facility => @authable)
        Factory.create(:user_price_group_member, :user => @director, :price_group => @price_group)
        @instrument_pp=@product.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :price_group_id => @price_group.id))
        @instrument_pp.reload.restrict_purchase=false
        @reservation.update_attributes(:actual_start_at => nil, :actual_end_at => nil)
        @now=@reservation.reserve_start_at+3.hour
        @reservation_attrs=Factory.attributes_for(
            :reservation,
            :actual_start_at => @now-2.hour,
            :actual_end_at => @now-1.hour
        )
        @params.merge!(:reservation => @reservation_attrs)
      end

      it 'should update the actuals and assign a price policy if there is none' do
        Timecop.freeze(@now) do
          maybe_grant_always_sign_in :director
          @order_detail.to_complete!
          do_request
          assigns(:order).should == @order
          assigns(:order_detail).should == @order_detail
          assigns(:reservation).should == @reservation
          assigns(:instrument).should == @product
          assigns(:reservation).actual_start_at.should == @reservation_attrs[:actual_start_at]
          assigns(:reservation).actual_end_at.should == @reservation_attrs[:actual_end_at]
          assigns(:order_detail).price_policy.should == @instrument_pp
          assigns(:order_detail).actual_cost.should_not be_nil
          assigns(:order_detail).actual_subsidy.should_not be_nil
          should set_the_flash
          should render_template 'edit'
        end
      end

    end

  end


  context 'show' do

    before :each do
      @method=:get
      @action=:show
    end

    it_should_allow_operators_only

  end


  context 'new' do

    before :each do
      @method=:get
      @action=:new
      @params={ :facility_id => @authable.url_name, :instrument_id => @product.url_name }
    end

    it_should_allow_operators_only

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @time = 1.hour.from_now.change(:sec => 0)
      @params={
        :facility_id => @authable.url_name,
        :instrument_id => @product.url_name,
        :reservation => Factory.attributes_for(:reservation, :reserve_start_at => @time, :reserve_end_at => @time + 1.hour)
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
          assigns[:reservation].should_not be_nil
          assigns[:reservation].should_not be_new_record
        end
        it 'should be an admin reservation' do
          assigns[:reservation].should be_admin
        end
        it 'should set the times' do
          assigns[:reservation].reserve_start_at.should == @time
          assigns[:reservation].reserve_end_at.should == (@time + 1.hour)
        end
        it "should redirect to the facility's schedule page" do
          response.should redirect_to facility_instrument_schedule_path
        end
      end

      context 'fails validations' do
        it 'should not allow a conflict with an existing reservation' do
          @params[:reservation] = Factory.attributes_for(:reservation)
          parametrize_dates(@params[:reservation], :reserve)
          do_request
          assigns[:reservation].should be_new_record
          response.should render_template :new
        end
      end
    end
  end


  context 'admin' do

    before :each do
      @reservation.order_detail_id=nil
      @reservation.save
      @reservation.reload
      @params={ :facility_id => @authable.url_name, :instrument_id => @product.url_name, :reservation_id => @reservation.id }
    end

    
    context 'edit_admin' do

      before :each do
        @method=:get
        @action=:edit_admin
      end

      it_should_allow_operators_only

    end


    context 'update_admin' do

      before :each do
        @method=:put
        @action=:update_admin
        @params.merge!(:reservation => Factory.attributes_for(:reservation))
      end

      it_should_allow_operators_only :redirect

    end

  end

end
