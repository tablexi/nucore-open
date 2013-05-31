require 'spec_helper'; require 'controller_spec_helper'

describe UsersController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryGirl.create(:facility)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
      @inactive_user = FactoryGirl.create(:user, :first_name => 'Inactive')

      @active_user = FactoryGirl.create(:user, :first_name => 'Active')
      place_and_complete_item_order(@active_user, @authable)
      # place two orders to make sure it only and_return the user once
      place_and_complete_item_order(@active_user, @authable)

      @lapsed_user = FactoryGirl.create(:user, :first_name => 'Lapsed')
      @old_order_detail = place_and_complete_item_order(@lapsed_user, @authable)
      @old_order_detail.order.update_attributes(:ordered_at => 400.days.ago)
    end

    it_should_allow_operators_only :success, 'include the right users' do
      assigns[:users].size.should == 1
      assigns[:users].should include @active_user
    end

    context 'with newly created user' do
      before :each do
        @user = FactoryGirl.create(:user)
        @params.merge!({ :user => @user.id })
      end
      it_should_allow_operators_only :success, 'set the user' do
        assigns[:new_user].should == @user
      end
    end

  end

  context 'creating users' do
    context 'enabled' do
      include_context "feature enabled", :create_users

      it "routes" do
        { :get => "/facilities/url_name/users/new" }.should route_to(:controller => 'users', :action => 'new', :facility_id => 'url_name')
        { :post => "/facilities/url_name/users" }.should route_to(:controller => 'users', :action => 'create', :facility_id => 'url_name')
        { :get => "/facilities/url_name/users/new_external" }.should route_to(:controller => 'users', :action => 'new_external', :facility_id => 'url_name')
        { :post => "/facilities/url_name/users/search" }.should route_to(:controller => 'users', :action => 'search', :facility_id => 'url_name')
      end

      context 'search' do
        before :each do
          @user = FactoryGirl.create(:user)
          @method = :post
          @action = :search
        end

        context 'blank post' do
          before :each do
            @params.merge!( :username_lookup => '')
          end

          it_should_allow_operators_only do
            assigns(:user).should be_nil
            response.should be_success
          end
        end

        context 'user already exists in database' do
          before :each do
            @params.merge!(:username_lookup => @user.username)
          end

          it_should_allow_operators_only do
            assigns(:user).should == @user
            assigns(:user).should be_persisted
          end
        end

        context 'user does not exist in database' do
          before :each do
            @user2 = FactoryGirl.build(:user)
            controller.stub(:service_username_lookup).with(@user2.username).and_return(@user2)
            @params.merge!(:username_lookup => @user2.username)
          end

          it_should_allow_operators_only do
            assigns(:user).should == @user2
            assigns(:user).should be_new_record
          end
        end
      end

      context 'new_external' do
        before :each do
          @method=:get
          @action=:new_external
        end

        it_should_allow_operators_only do
          expect(assigns(:user)).to be_kind_of User
          assigns(:user).should be_new_record
        end
      end

      context "create" do
        before :each do
          @method=:post
          @action=:create

        end

        context 'external user' do
          context 'with successful parameters' do
            before :each do
              @params.merge!(:group_name => UserRole::FACILITY_DIRECTOR, :user => FactoryGirl.attributes_for(:user))
            end

            it_should_allow_operators_only :redirect do
              expect(assigns(:user)).to be_kind_of User
              assigns(:user).should be_persisted
              assert_redirected_to facility_users_url(:user => assigns[:user].id)
            end
          end

          context 'with missing parameters' do
            before :each do
              @params.merge!(:user => {})
            end

            it_should_allow_operators_only do
              assigns(:user).should be_new_record
              response.should render_template 'new_external'
            end
          end
        end

        context 'internal user' do
          before :each do
            sign_in @admin
          end

          context 'user already exists' do
            before :each do
              @user = FactoryGirl.create(:user)
              @params.merge!(:username => @user.username)
              do_request
            end

            it 'flashes an error' do
              should set_the_flash
              response.should redirect_to facility_users_path
            end
          end

          context 'user added' do
            before :each do
              @ldap_user = FactoryGirl.build(:user)
              controller.stub(:service_username_lookup).with(@ldap_user.username).and_return(@ldap_user)
              @params.merge!(:username => @ldap_user.username)
              do_request
            end

            it 'should save the user' do
              assigns(:user).should be_persisted
            end

            it 'should set the flash' do
              flash[:notice].should_not be_empty
            end

            it 'should redirect' do
              response.should redirect_to facility_users_path(:user => assigns(:user).id)
            end
          end
        end
      end
    end

    context 'disabled' do
      include_context "feature disabled", :create_users
      it "doesn't route route" do
        { :get => "/facilities/url_name/users/new" }.should_not be_routable
        { :post => "/facilities/url_name/users" }.should_not be_routable
        { :get => "/facilities/url_name/users/new_external" }.should_not be_routable
        { :post => "/facilities/url_name/users/search" }.should_not be_routable
      end
    end
  end

  context 'switch_to' do

    before :each do
      @method=:get
      @action=:switch_to
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only :redirect do
      assigns(:user).should == @guest
      session[:acting_user_id].should == @guest.id
      session[:acting_ref_url].should == facility_users_path
      assert_redirected_to facility_path(@authable)
    end

  end

  context "orders" do
    before :each do
      @method=:get
      @action=:orders
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only do
      expect(assigns(:user)).to eq(@guest)
      expect(assigns(:order_details)).to be_kind_of ActiveRecord::Relation
    end
  end

  context "reservations" do
    before :each do
      @method=:get
      @action=:reservations
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only do
      expect(assigns(:user)).to eq(@guest)
      expect(assigns(:order_details)).to be_kind_of ActiveRecord::Relation
    end
  end

end
