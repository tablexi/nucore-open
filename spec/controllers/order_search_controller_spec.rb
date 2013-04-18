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
      it_should_deny(:guest)
    end

    context 'signed in as admin' do
      before :each do
        sign_in @admin
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