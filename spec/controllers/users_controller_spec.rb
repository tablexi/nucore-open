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
      expect(assigns[:users].size).to eq(1)
      expect(assigns[:users]).to include @active_user
    end

    context 'with newly created user' do
      before :each do
        @user = FactoryGirl.create(:user)
        @params.merge!({ :user => @user.id })
      end
      it_should_allow_operators_only :success, 'set the user' do
        expect(assigns[:new_user]).to eq(@user)
      end
    end

  end

  context 'creating users' do
    context 'enabled' do
      include_context "feature enabled", :create_users

      it "routes" do
        expect({ :get => "/facilities/url_name/users/new" }).to route_to(:controller => 'users', :action => 'new', :facility_id => 'url_name')
        expect({ :post => "/facilities/url_name/users" }).to route_to(:controller => 'users', :action => 'create', :facility_id => 'url_name')
        expect({ :get => "/facilities/url_name/users/new_external" }).to route_to(:controller => 'users', :action => 'new_external', :facility_id => 'url_name')
        expect({ :post => "/facilities/url_name/users/search" }).to route_to(:controller => 'users', :action => 'search', :facility_id => 'url_name')
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
            expect(assigns(:user)).to be_nil
            expect(response).to be_success
          end
        end

        context 'user already exists in database' do
          before :each do
            @params.merge!(:username_lookup => @user.username)
          end

          it_should_allow_operators_only do
            expect(assigns(:user)).to eq(@user)
            expect(assigns(:user)).to be_persisted
          end
        end

        context 'user does not exist in database' do
          before :each do
            @user2 = FactoryGirl.build(:user)
            allow(controller).to receive(:service_username_lookup).with(@user2.username).and_return(@user2)
            @params.merge!(:username_lookup => @user2.username)
          end

          it_should_allow_operators_only do
            expect(assigns(:user)).to eq(@user2)
            expect(assigns(:user)).to be_new_record
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
          expect(assigns(:user)).to be_new_record
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
              expect(assigns(:user)).to be_persisted
              assert_redirected_to facility_users_url(:user => assigns[:user].id)
            end
          end

          context 'with missing parameters' do
            before :each do
              @params.merge!(:user => {})
            end

            it_should_allow_operators_only do
              expect(assigns(:user)).to be_new_record
              expect(response).to render_template 'new_external'
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
              is_expected.to set_the_flash
              expect(response).to redirect_to facility_users_path
            end
          end

          context 'user added' do
            before :each do
              @ldap_user = FactoryGirl.build(:user)
              allow(controller).to receive(:service_username_lookup).with(@ldap_user.username).and_return(@ldap_user)
              @params.merge!(:username => @ldap_user.username)
              do_request
            end

            it 'should save the user' do
              expect(assigns(:user)).to be_persisted
            end

            it 'should set the flash' do
              expect(flash[:notice]).not_to be_empty
            end

            it 'should redirect' do
              expect(response).to redirect_to facility_users_path(:user => assigns(:user).id)
            end
          end
        end
      end
    end

    context 'disabled' do
      include_context "feature disabled", :create_users
      it "doesn't route route" do
        expect({ :get => "/facilities/url_name/users/new" }).not_to be_routable
        expect({ :post => "/facilities/url_name/users" }).not_to be_routable
        expect({ :get => "/facilities/url_name/users/new_external" }).not_to be_routable
        expect({ :post => "/facilities/url_name/users/search" }).not_to be_routable
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
      expect(assigns(:user)).to eq(@guest)
      expect(session[:acting_user_id]).to eq(@guest.id)
      expect(session[:acting_ref_url]).to eq(facility_users_path)
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

  context "accounts" do
    before :each do
      @method=:get
      @action=:accounts
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only do
      expect(assigns(:user)).to eq(@guest)
      expect(assigns(:accounts)).to be_kind_of ActiveRecord::Relation
    end
  end

end
