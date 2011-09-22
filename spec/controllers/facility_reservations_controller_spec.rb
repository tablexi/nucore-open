require 'spec_helper'; require 'controller_spec_helper'

describe FacilityReservationsController do
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
      :ordered_at => Time.zone.now
    )
    @reservation=Factory.create(:reservation, :instrument => @product)
    @order_detail=Factory.create(:order_detail, :order => @order, :product => @product, :reservation => @reservation)
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


  context 'update' do

    before :each do
      @method=:put
      @action=:update
      @params.merge!(:reservation => Factory.attributes_for(:reservation))
    end

    it_should_allow_operators_only

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
      @params={
        :facility_id => @authable.url_name,
        :instrument_id => @product.url_name,
        :reservation => Factory.attributes_for(:reservation)
      }
    end

    it_should_allow_operators_only :redirect

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
