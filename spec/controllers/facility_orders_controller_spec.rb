require 'spec_helper'; require 'controller_spec_helper'

describe FacilityOrdersController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @product=Factory.create(:item,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @account=create_nufs_account_with_owner
    @order_detail = place_product_order(@director, @authable, @product, @account)
    @order_detail.order.update_attributes!(:state => 'purchased')
    @params={ :facility_id => @authable.url_name }
  end

  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_operators_only {}

    context 'signed in' do
      before :each do
        maybe_grant_always_sign_in :director
      end
      ['order_number','date', 'product', 'assigned_to', 'status'].each do |sort|
        it "should not blow up for sort by #{sort}" do
          @params[:sort] = sort
          do_request
          response.should be_success          
          assigns[:order_details].should_not be_nil
          assigns[:order_details].first.should_not be_nil
        end
      end

      it 'should not return reservations' do
        # setup_reservation overwrites @order_detail
        @order_detail_item = @order_detail
        @order_detail_reservation = setup_reservation(@authable, @facility_account, @account, @director)
        @reservation = place_reservation(@authable, @order_detail_reservation, Time.zone.now + 1.hour)

        @authable.reload.order_details.should contain_all [@order_detail_item, @order_detail_reservation]
        do_request
        assigns[:order_details].should == [@order_detail_item]
      end
    end
  end


  context 'show' do

    before :each do
      @method=:get
      @action=:show
      @params.merge!(:id => @order.id)
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      assigns(:order).should == @order
      should render_template 'show'
    end

  end


  context 'batch_update' do

    before :each do
      @method=:post
      @action=:batch_update
    end

    it_should_allow_operators_only :redirect

  end


  context 'show_problems' do

    before :each do
      @method=:get
      @action=:show_problems
    end

    it_should_allow_managers_only

  end


  context 'disputed' do

    before :each do
      @method=:get
      @action=:disputed
    end

    it_should_allow_operators_only

  end

  context 'tab_counts' do
    before :each do
      @method = :get
      @action = :tab_counts
      @order_detail2=Factory.create(:order_detail, :order => @order, :product => @product)
      
      @authable.order_details.non_reservations.new_or_inprocess.size.should == 2

      @problem_order_details = (1..3).map do |i|
        order_detail = place_and_complete_item_order(@staff, @authable)
        order_detail.update_attributes(:price_policy_id => nil)
        order_detail
      end
      

      @disputed_order_details = (1..4).map do |i|
        order_detail = place_and_complete_item_order(@staff, @authable)
        order_detail.update_attributes({
          :dispute_at => Time.zone.now,
          :dispute_resolved_at => nil,
          :dispute_reason => 'because'
        })
        order_detail
      end
      @authable.order_details.in_dispute.size.should == 4

      @params.merge!(:tabs => ['new_or_in_process_orders', 'disputed_orders', 'problem_orders'])
    end

    it_should_allow_operators_only {}
    
    context 'signed in' do
      before :each do
        maybe_grant_always_sign_in :director
      end
      it 'should get only new if thats all you ask for' do
        @authable.order_details.non_reservations.new_or_inprocess.to_sql
        @params[:tabs] = ['new_or_in_process_orders']
        do_request
        response.should be_success
        body = JSON.parse(response.body)
        body.keys.should contain_all ['new_or_in_process_orders']
        body['new_or_in_process_orders'].should == 2
      end

      it 'should get everything if you ask for it' do
        do_request
        response.should be_success
        body = JSON.parse(response.body)
        body.keys.should contain_all ['new_or_in_process_orders', 'disputed_orders', 'problem_orders']
        body['new_or_in_process_orders'].should == 2
        body['problem_orders'].should == 3
        body['disputed_orders'].should == 4
      end
    end
  end

end
