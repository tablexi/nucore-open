require 'spec_helper'; require 'controller_spec_helper'

describe FacilityFacilityAccountsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable, :created_by => @admin.id)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_managers_only do
      should assign_to(:accounts).with_kind_of Array
      assigns(:accounts).size.should == 1
      assigns(:accounts)[0].should == @facility_account
      should render_template 'index'
    end

  end


  context 'new' do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_managers_only do
      should assign_to(:facility_account).with_kind_of FacilityAccount
      assigns(:facility_account).should be_new_record
      should render_template 'new'
    end

  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
      @params.merge!(:id => @facility_account.id, :facility_account => Factory.attributes_for(:facility_account))
    end

    it_should_allow_managers_only :redirect do
      should assign_to(:facility_account).with_kind_of FacilityAccount
      assigns(:facility_account).should == @facility_account
      should set_the_flash
      assert_redirected_to facility_facility_accounts_path
    end

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(:facility_account => Factory.attributes_for(:facility_account))
    end

    it_should_allow_managers_only :redirect do |user|
      should assign_to(:facility_account).with_kind_of FacilityAccount
      assigns(:facility_account).created_by.should == user.id
      should set_the_flash
      assert_redirected_to facility_facility_accounts_path
    end

  end


  context 'edit' do

    before :each do
      @method=:get
      @action=:edit
      @params.merge!(:id => @facility_account.id)
    end

    it_should_allow_managers_only do
      should assign_to(:facility_account).with_kind_of FacilityAccount
      assigns(:facility_account).should == @facility_account
      should render_template 'edit'
    end

  end

end