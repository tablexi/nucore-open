require 'spec_helper'
require 'controller_spec_helper'

def it_should_find_the_order(desc = '')
  it 'should find the order ' + desc do
    get :index, :search => order.id.to_s
    assigns(:order_details).should == [order_detail]
  end
end

def it_should_not_find_the_order(desc = '')
  it 'should not find the order ' + desc do
    get :index, :search => order.id.to_s
    assigns(:order_details).should be_empty
  end
end

def it_should_have_admin_edit_paths
  render_views
  it 'should have link to the admin path' do
    get :index, :search => order.id.to_s
    response.body.should include edit_facility_order_order_detail_path(order_detail.facility, order_detail.order, order_detail)
    response.body.should include edit_facility_order_path(order.facility, order)
  end
end

def it_should_have_customer_paths
  render_views
  it 'should have links to the customer view' do
    get :index, :search => order.id.to_s
    response.body.should include order_order_detail_path(order_detail.order, order_detail)
    response.body.should include order_path(order)
  end
end


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

      context 'when it is purchased for the user' do
        before :each do
          order.update_attributes(:user => @guest)
        end

        it_should_find_the_order
        it_should_have_customer_paths
      end

      context 'when it is purchased for another user' do
        before :each do
          order.update_attributes(:user => @admin)
        end

        it_should_not_find_the_order
      end
    end

    context 'when signed in as a facility admin' do
      before :each do
        grant_role(@staff, facility)
        sign_in @staff
      end

      it_should_find_the_order 'even if it is under a different user'
      it_should_have_admin_edit_paths
    end

    context 'when signed in as facility admin for a different facility' do
      let(:facility2) { FactoryGirl.create :facility }
      before :each do
        grant_role(@staff, facility2)
        sign_in @staff
      end

      it_should_not_find_the_order
    end

    context 'when signed in as facility admin, but order was placed for the user in a different facility' do
      let(:facility2) { FactoryGirl.create :setup_facility }
      let!(:product) { FactoryGirl.create(:setup_item, :facility => facility2) }
      let!(:order) { FactoryGirl.create(:purchased_order, :product => product) }
      let!(:order_detail) { order.order_details.first }
      let(:user) { order.user }
      before :each do
        grant_role user, facility
        sign_in user
      end

      it_should_find_the_order
      it_should_have_customer_paths
    end

    context 'when signed in as a billing manager' do
      before :each do
        sign_in @billing_admin
      end

      it_should_find_the_order
      it_should_have_admin_edit_paths
    end

    describe 'account roles' do
      context 'when signed in as a business admin' do
        before :each do
          sign_in @staff
          AccountUser.grant(@staff, AccountUser::ACCOUNT_ADMINISTRATOR, order_detail.account, @admin)
        end

        it_should_find_the_order
        it_should_have_customer_paths
      end

      context 'when signed in as a purchaser' do
        before :each do
          sign_in @staff
          AccountUser.grant(@staff, AccountUser::ACCOUNT_PURCHASER, order_detail.account, @admin)
        end

        it_should_not_find_the_order
      end

      context 'when signed in as an account owner' do
        before :each do
          sign_in @staff
          order_detail.account.add_or_update_member(@staff,  AccountUser::ACCOUNT_OWNER, @admin)
        end

        it_should_find_the_order
        it_should_have_customer_paths
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

      it_should_find_the_order
      it_should_have_admin_edit_paths

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