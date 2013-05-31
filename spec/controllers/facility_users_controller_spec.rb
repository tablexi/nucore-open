require 'spec_helper'; require 'controller_spec_helper'

describe FacilityUsersController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
      grant_role(@staff)
    end

    it_should_allow_managers_only do |user|
      expect(assigns(:users)).to be_kind_of Array
      assigns(:users).size.should >= 1
      assigns(:users).should be_include @staff
      assigns(:users).should be_include user unless user == @admin
    end

  end


  context 'destroy' do

    before :each do
      @method=:delete
      @action=:destroy
      grant_role(@staff)
      @params.merge!(:id => @staff.id)
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:user)).to be_kind_of User
      assigns(:user).should == @staff
      @staff.reload.facility_user_roles(@authable).should be_empty
      assert_redirected_to facility_facility_users_url
    end

  end


  context 'search' do

    before :each do
      @method=:get
      @action=:search
    end

    it_should_allow_managers_only { should render_template('search') }

  end


  context 'map_user' do

    before :each do
      @method=:post
      @action=:map_user
      @params.merge!(:facility_user_id => @staff.id, :user_role => { :role => UserRole::FACILITY_STAFF })
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:user)).to be_kind_of User
      assigns(:user).should == @staff
      expect(assigns(:user_role)).to be_kind_of UserRole
      assigns(:user_role).user.should == @staff
      assigns(:user_role).facility.should == @authable
      assert_redirected_to facility_facility_users_url
    end

  end

end
