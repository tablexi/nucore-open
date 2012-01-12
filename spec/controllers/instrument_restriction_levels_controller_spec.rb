require 'spec_helper'
require 'controller_spec_helper'

describe InstrumentRestrictionLevelsController do
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
      @level = Factory.create(:instrument_restriction_level, :instrument_id => @instrument.id)
      @level2 = Factory.create(:instrument_restriction_level, :instrument_id => @instrument.id)
      @instrument2 = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @level3 = Factory.create(:instrument_restriction_level, :instrument_id => @instrument2.id)
      
      @action = :index
      @method = :get
    end
    it_should_allow_managers_only :success, 'see index' do
      assigns[:facility].should == @authable
      assigns[:instrument].should == @instrument
      assigns[:instrument_restriction_levels].should == [@level, @level2]
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
      assigns[:instrument_restriction_level].should be_new_record
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
        @params.merge!({:instrument_restriction_level => Factory.attributes_for(:instrument_restriction_level)})
      end
      it_should_allow_managers_only :redirect, 'do create' do
        assigns[:facility].should == @authable
        assigns[:instrument].should == @instrument
        assigns[:instrument_restriction_level].should_not be_new_record
        flash[:notice].should_not be_nil
        response.should redirect_to(facility_instrument_instrument_restriction_levels_path(@authable, @instrument))
      end      
    end
    context 'missing data' do
      before :each do
        @params.merge!({:instrument_restriction_level => Factory.attributes_for(:instrument_restriction_level, :name => '')})
      end
      it_should_allow_managers_only :success, 'do create' do
        assigns[:facility].should == @authable
        assigns[:instrument].should == @instrument
        assigns[:instrument_restriction_level].should be_new_record
        assigns[:instrument_restriction_level].errors.should_not be_empty
        response.should render_template :new
      end
    end
  end
  
  context 'edit' do
    before :each do
      @action = :edit
      @method = :get
      @instrument_restriction_level = Factory.create(:instrument_restriction_level, :instrument_id => @instrument.id)
      @params.merge!({:id => @instrument_restriction_level})
    end
    it_should_allow_managers_only :success, 'do edit' do
      assigns[:facility].should == @authable
      assigns[:instrument].should == @instrument
      assigns[:instrument_restriction_level].should == @instrument_restriction_level
      response.should render_template :edit
    end
  end
  context 'update' do
    before :each do
      @action = :update
      @method = :post
      @instrument_restriction_level = Factory.create(:instrument_restriction_level, :instrument_id => @instrument.id)
      @params.merge!({:id => @instrument_restriction_level.id})
    end
    context 'correct info' do
      before :each do
        @params.merge!({:instrument_restriction_level => {:name => 'new name'}})
      end
      it_should_allow_managers_only :redirect, 'do update' do
        assigns[:facility].should == @authable
        assigns[:instrument].should == @instrument
        assigns[:instrument_restriction_level].should == @instrument_restriction_level
        assigns[:instrument_restriction_level].name.should == 'new name'
        flash[:notice].should_not be_nil
        response.should redirect_to(facility_instrument_instrument_restriction_levels_path(@authable, @instrument))
      end      
    end
    context 'missing data' do
      before :each do
        @params.merge!({:instrument_restriction_level => {:name => ''}})
      end
      it_should_allow_managers_only :success, 'do update' do
        assigns[:facility].should == @authable
        assigns[:instrument].should == @instrument
        assigns[:instrument_restriction_level].should == @instrument_restriction_level
        assigns[:instrument_restriction_level].errors.should_not be_empty
        response.should render_template :edit
      end
    end
  end
  
  context 'destroy' do
    before :each do
      @method=:delete
      @action=:destroy
      @instrument_restriction_level = Factory.create(:instrument_restriction_level, :instrument_id => @instrument.id)
      @params.merge!({:id => @instrument_restriction_level.id})
    end
    it_should_allow_managers_only :redirect, 'do delete' do
      assigns[:instrument_restriction_level].should be_destroyed
      flash[:notice].should_not be_nil
      response.should redirect_to(facility_instrument_instrument_restriction_levels_path(@authable, @instrument))
    end
  end
  
end
