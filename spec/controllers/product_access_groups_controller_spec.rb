require 'spec_helper'
require 'controller_spec_helper'

describe ProductAccessGroupsController do
  render_views
  before :all do
    create_users
  end  
  
  before :each do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument       = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @params={ :instrument_id => @instrument.url_name, :facility_id => @authable.url_name }    
  end
  
  context 'index' do
    before :each do
      @level = Factory.create(:product_access_group, :product => @instrument)
      @level2 = Factory.create(:product_access_group, :product => @instrument)
      @instrument2 = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @level3 = Factory.create(:product_access_group, :product => @instrument2)
      
      @action = :index
      @method = :get
    end
    it_should_allow_managers_only :success, 'see index' do
      assigns[:facility].should == @authable
      assigns[:instrument].should == @instrument
      assigns[:product_access_groups].should == [@level, @level2]
    end
  end
  
  context 'new' do
    before :each do
      @action = :new
      @method = :get
    end
    it_should_allow_managers_only :success, 'do new' do
      assigns[:facility].should == @authable
      assigns[:instrument].should == @instrument
      assigns[:product_access_group].should be_new_record
      response.should render_template :new
    end
  end
  
  context 'create' do
    before :each do
      @action = :create
      @method = :post
    end
    context 'correct info' do
      before :each do
        @params.merge!({:product_access_group => Factory.attributes_for(:product_access_group)})
      end
      it_should_allow_managers_only :redirect, 'do create' do
        assigns[:facility].should == @authable
        assigns[:instrument].should == @instrument
        assigns[:product_access_group].should_not be_new_record
        flash[:notice].should_not be_nil
        response.should redirect_to(facility_instrument_product_access_groups_path(@authable, @instrument))
      end      
    end
    context 'missing data' do
      before :each do
        @params.merge!({:product_access_group => Factory.attributes_for(:product_access_group, :name => '')})
      end
      it_should_allow_managers_only :success, 'do create' do
        assigns[:facility].should == @authable
        assigns[:instrument].should == @instrument
        assigns[:product_access_group].should be_new_record
        assigns[:product_access_group].errors.should_not be_empty
        response.should render_template :new
      end
    end
  end
  
  context 'edit' do
    before :each do
      @action = :edit
      @method = :get
      @product_access_group = Factory.create(:product_access_group, :product_id => @instrument.id)
      @params.merge!({:id => @product_access_group})
    end
    it_should_allow_managers_only :success, 'do edit' do
      assigns[:facility].should == @authable
      assigns[:instrument].should == @instrument
      assigns[:product_access_group].should == @product_access_group
      response.should render_template :edit
    end
  end
  context 'update' do
    before :each do
      @action = :update
      @method = :post
      @product_access_group = Factory.create(:product_access_group, :product_id => @instrument.id)
      @params.merge!({:id => @product_access_group.id})
    end
    context 'correct info' do
      before :each do
        @params.merge!({:product_access_group => {:name => 'new name'}})
      end
      it_should_allow_managers_only :redirect, 'do update' do
        assigns[:facility].should == @authable
        assigns[:instrument].should == @instrument
        assigns[:product_access_group].should == @product_access_group
        assigns[:product_access_group].name.should == 'new name'
        flash[:notice].should_not be_nil
        response.should redirect_to(facility_instrument_product_access_groups_path(@authable, @instrument))
      end      
    end
    context 'missing data' do
      before :each do
        @params.merge!({:product_access_group => {:name => ''}})
      end
      it_should_allow_managers_only :success, 'do update' do
        assigns[:facility].should == @authable
        assigns[:instrument].should == @instrument
        assigns[:product_access_group].should == @product_access_group
        assigns[:product_access_group].errors.should_not be_empty
        response.should render_template :edit
      end
    end
  end
  
  context 'destroy' do
    before :each do
      @method=:delete
      @action=:destroy
      @product_access_group = Factory.create(:product_access_group, :product => @instrument)
      @params.merge!({:id => @product_access_group.id})
    end
    it_should_allow_managers_only :redirect, 'do delete' do
      assigns[:product_access_group].should be_destroyed
      flash[:notice].should_not be_nil
      response.should redirect_to(facility_instrument_product_access_groups_path(@authable, @instrument))
    end
  end
  
end
