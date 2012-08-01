require 'spec_helper'
require 'controller_spec_helper'
describe OrderStatusesController do
  render_views
  before(:all) { create_users }
  before :each do
    # remove the default ones so they're not in the way
    OrderStatus.all.each { |os| os.destroy }
    OrderStatus.all.should be_empty

    @authable = @facility = Factory.create(:facility)
    
    @root_status = Factory.create(:order_status)
    @root_status.should be_root
    @root_status2 = Factory.create(:order_status)
    @root_status2.should be_root
    @order_status = Factory.create(:order_status, :facility => @facility, :parent => @root_status)
    @order_status2 = Factory.create(:order_status, :facility => @facility, :parent => @root_status)
    OrderStatus.all.size.should == 4
    @params = { :facility_id => @facility.url_name }
  end

  def self.it_should_disallow_editing_root_statuses
    it 'should disallow editing root statuses' do
      @root_status.should_not be_editable
      @params[:id] = @root_status.id
      maybe_grant_always_sign_in :director
      do_request
      response.code.should == "404"
    end
  end

  context 'index' do
    before :each do
      @action = :index
      @method = :get
    end
    
    it_should_allow_managers_only {}
    
    context 'signed in' do
      before :each do
        maybe_grant_always_sign_in :director
        do_request
      end
      it 'should be a success' do
        response.should be_success
      end
      it 'should have all statuses' do
        assigns[:order_statuses].should contain_all [@root_status, @root_status2, @order_status, @order_status2]
      end
      it 'should have the root statuses' do
        assigns[:root_order_statuses].should contain_all [@root_status, @root_status2]
      end
    end
  end

  context 'new' do
    before :each do
      @action = :new
      @method = :get
    end
    it_should_allow_managers_only {}
    context 'signed in' do
      before :each do
        maybe_grant_always_sign_in :director
        do_request
      end
      it 'should create a new record' do
        assigns[:order_status].should be_new_record
      end
      it 'should set the facility' do
        assigns[:order_status].facility.should == @facility
      end
    end
  end

  context 'create' do
    before :each do
      @action = :create
      @method = :post
      @params.merge!(:order_status => Factory.attributes_for(:order_status, :parent_id => @root_status.id))
    end
    it_should_allow_managers_only(:redirect) {}
    context 'signed_in' do
      before :each do
        maybe_grant_always_sign_in :director
      end
      context 'success' do
        before :each do
          do_request
        end
        it 'should save the record to the database' do
          assigns[:order_status].should_not be_new_record
        end
        it 'should redirect' do
          response.should redirect_to facility_order_statuses_url
        end
        it 'should set the flash' do
          should set_the_flash
        end
        it 'should save the parent' do
          assigns[:order_status].parent.should == @root_status
        end
        it 'should set the facility' do
          assigns[:order_status].facility.should == @facility
        end
      end
      context 'failure' do
        context 'without name' do
          before :each do
            @params[:order_status][:name] = ''
            do_request
          end
          it 'should not save to the database' do
            assigns[:order_status].should be_new_record
          end
          it 'should render new' do
            response.should render_template :new
          end
        end
      end
    end
  end
  context 'edit' do
    before :each do
      @action = :edit
      @method = :get
      @params.merge!(:id => @order_status.id)
    end
    it_should_allow_managers_only {}
    it_should_disallow_editing_root_statuses
    context 'signed in' do
      before :each do
        maybe_grant_always_sign_in :director
        do_request
      end
      it 'should set the order status' do
        assigns[:order_status].should == @order_status
      end
    end
  end
  
  context 'update' do
    before :each do
      @action = :update
      @method = :put
      @params.merge!(:id => @order_status.id, :order_status =>  Factory.attributes_for(:order_status, :parent_id => @root_status.id))
    end
    it_should_allow_managers_only :redirect
    it_should_disallow_editing_root_statuses
  end

  context 'destroy' do
    before :each do
      @action = :destroy
      @method = :delete
      @params.merge!(:id => @order_status.id)
    end
    it_should_allow_managers_only(:redirect) {}
    it_should_disallow_editing_root_statuses

    context 'signed in' do
      before(:each) { maybe_grant_always_sign_in :director }
      context 'success' do
        before :each do
          @user = Factory.create(:user)
          @facility_account = Factory.create(:facility_account, :facility => @facility)
          @product = Factory.create(:item, :facility => @facility, :facility_account => @facility_account)
          @order_details = []
          3.times do
            order_detail = place_product_order(@user, @facility, @product)
            order_detail.change_status! @order_status
            @order_details << order_detail
          end
          do_request
        end
        it 'should set the record' do
          assigns[:order_status].should == @order_status
        end
        it 'should destroy the record' do
          assigns[:order_status].should be_destroyed
        end
        it 'should redirect' do
          response.should redirect_to facility_order_statuses_url(:facility_id => @facility.url_name)
        end
        it 'should set all order details to parent status' do
          @order_details.each { |od| od.reload.order_status.should == @root_status }
        end
      end
    end
  end

end