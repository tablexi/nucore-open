require 'spec_helper'
require 'controller_spec_helper'

describe OrderSearchController do
  before(:all) { create_users }
  let!(:product) { FactoryGirl.create(:setup_item) }
  let!(:order) { FactoryGirl.create(:purchased_order, :product => product) }
  let!(:order_detail) { order.order_details.first }
  let!(:facility) { order.facility }

  describe 'index' do
    describe 'permissions' do
      before :each do
        @action = :index
        @method = :get
      end

      it_should_require_login
    end

    context 'signed in as a normal user' do
      before :each do
        sign_in @guest
      end

      it 'should return the order if it is assigned to the user' do
        order.update_attributes(:user => @guest)
        get :index, :search => order.id.to_s
        assigns(:order_details).should == [order_detail]
      end

      it 'should not return the order if it is assigned to another user' do
        order.update_attributes(:user => @admin)
        get :index, :search => order.id.to_s
        assigns(:order_details).should be_empty
      end
    end

    context 'when signed in as a facility admin' do
      before :each do
        grant_role(@staff, facility)
        sign_in @staff
      end

      it 'should return the order even if it is under a different user' do
        get :index, :search => order.id.to_s
        assigns(:order_details).should == [order_detail]
      end
    end

    context 'when signed in as facility admin for a different facility' do
      let(:facility2) { FactoryGirl.create :facility }
      before :each do
        grant_role(@staff, facility2)
        sign_in @staff
      end

      it 'should not return the order' do
        get :index, :search => order.id.to_s
        assigns(:order_details).should be_empty
      end
    end


    context 'signed in as admin' do
      before :each do
        sign_in @admin
      end

      it 'should not return an unpurchased order' do
        order2 = FactoryGirl.create(:setup_order, :product => product)
        get :index, :search => order2.id.to_s
        assigns(:order_details).should be_empty
      end

      it 'should return an order with the id' do
        get :index, :search => order.id.to_s
        assigns(:order_details).should =~ [order_detail]
      end

      it 'should return the order detail with the id' do
        get :index, :search => order_detail.id.to_s
        assigns(:order_details).should =~ [order_detail]
      end

      context 'when there is an order and order detail with same ids' do
        let!(:order2) { FactoryGirl.create(:purchased_order, :id => order_detail.id, :product => product) }
        before :each do
          get :index, :search => order_detail.id.to_s
        end

        it 'should include both order and order detail' do
          assigns(:order_details).should =~ [order2.order_details.first, order_detail]
        end

        it 'should render a template' do
          response.should render_template 'index'
        end
      end

      context 'when including the dash' do
        before :each do
          get :index, :search => order_detail.to_s
        end

        it 'should redirect to order detail' do
          assigns(:order_details).should == [order_detail]
        end
      end
    end
  end
end