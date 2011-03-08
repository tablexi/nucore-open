require 'spec_helper'; require 'controller_spec_helper'

describe PriceGroupsController do
  integrate_views

  before(:all) { create_users }

  before :each do
    @authable=Factory.create(:facility)
    @price_group=Factory.create(:price_group, :facility => @authable)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_managers_only do
      should assign_to(:price_groups).with_kind_of Array
      assigns(:price_groups).should == @authable.price_groups
    end

  end


  context 'new' do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_managers_only do
      should assign_to(:price_group).with_kind_of PriceGroup
      should render_template 'new.html.haml'
    end

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(:price_group => Factory.attributes_for(:price_group, :facility => @authable))
    end

    it_should_allow_managers_only :redirect do
      should assign_to(:price_group).with_kind_of PriceGroup
      should set_the_flash
      assert_redirected_to [@authable, assigns(:price_group)]
    end

  end


  context 'with price group id' do

    before(:each) { @params.merge!(:id => @price_group.id) }

    context 'show' do

      before :each do
        @method=:get
        @action=:show
      end

      it_should_allow_managers_only :redirect do
        should assign_to(:price_group).with_kind_of PriceGroup
        assigns(:price_group).should == @price_group
        assert_redirected_to accounts_facility_price_group_path(@authable, assigns(:price_group))
      end

    end


    context 'users' do

      before :each do
        @method=:get
        @action=:users
      end

      it_should_allow_managers_only do
        should assign_to(:user_members).with_kind_of Array
        should assign_to(:tab)
        should render_template 'show.html.haml'
      end

    end


    context 'accounts' do

      before :each do
        @method=:get
        @action=:accounts
      end

      it_should_allow_managers_only do
        should assign_to(:account_members).with_kind_of Array
        should assign_to(:tab)
        should render_template 'show.html.haml'
      end

    end


    context 'edit' do

      before :each do
        @method=:get
        @action=:edit
      end

      it_should_allow_managers_only do
        should assign_to(:price_group).with_kind_of PriceGroup
        assigns(:price_group).should == @price_group
        should render_template 'edit.html.haml'
      end

    end


    context 'update' do

      before :each do
        @method=:put
        @action=:update
        @params.merge!(:price_group => Factory.attributes_for(:price_group, :facility => @authable))
      end

      it_should_allow_managers_only :redirect do
        should assign_to(:price_group).with_kind_of PriceGroup
        assigns(:price_group).should == @price_group
        should set_the_flash
        assert_redirected_to [@authable, @price_group]
      end

    end


    context 'destroy' do

      before :each do
        @method=:delete
        @action=:destroy
      end

      it_should_allow_managers_only :redirect do
        should assign_to(:price_group).with_kind_of PriceGroup
        assigns(:price_group).should == @price_group
        should_be_destroyed @price_group
        assert_redirected_to facility_price_groups_url
      end

    end

  end

end
