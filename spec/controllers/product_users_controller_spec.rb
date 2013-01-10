require 'spec_helper'
require 'controller_spec_helper'

describe ProductUsersController do
  render_views
  
  before(:all) { create_users }

  before(:each) do
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @price_group      = @authable.price_groups.create(FactoryGirl.attributes_for(:price_group))
    @instrument       = @authable.instruments.create(FactoryGirl.attributes_for(:instrument, :facility_account_id => @facility_account.id, :requires_approval => true))
    @price_policy     = @instrument.instrument_price_policies.create(FactoryGirl.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id))
    @price_policy.should be_valid
    @params={ :facility_id => @authable.url_name, :instrument_id => @instrument.url_name }
    
    @rule=@instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    @level = FactoryGirl.create(:product_access_group, :product_id => @instrument.id)
    @level2 = FactoryGirl.create(:product_access_group, :product_id => @instrument.id)
  end
  
  context "index" do
    before :each do
      @method = :get
      @action = :index
      @guest_product = ProductUser.create(:product => @instrument, :user => @guest, :approved_by => @admin.id, :approved_at => Time.zone.now)
      @staff_product = ProductUser.create(:product => @instrument, :user => @staff, :approved_by => @admin.id, :approved_at => Time.zone.now)
    end
    it "should only return the two users" do
      sign_in @admin
      do_request
      assigns[:product_users].should == [@guest_product, @staff_product]
    end
    
    it "should return empty and a flash if the product is not restricted" do
      @instrument.update_attributes(:requires_approval => false)
      sign_in @admin
      do_request
      assigns[:product_users].should be_nil
      flash[:notice].should_not be_empty
    end
    
  end
  context "update_restrictions" do
    before :each do
      @guest_product = ProductUser.create(:product => @instrument, :user => @guest, :approved_by => @admin.id, :approved_at => Time.zone.now)
      @staff_product = ProductUser.create(:product => @instrument, :user => @staff, :approved_by => @admin.id, :approved_at => Time.zone.now)
      
      @action = :update_restrictions
      @method = :put
      @params.deep_merge!({
        :instrument => {:product_users => {
          @guest_product.id => { :product_access_group_id => @level.id},
          @staff_product.id => { :product_access_group_id => @level2.id} 
        }
        } 
      })
    end
        
    it_should_allow_operators_only :redirect, "update the product_users" do
      ProductUser.find(@guest_product.id).product_access_group.should == @level
      ProductUser.find(@staff_product.id).product_access_group.should == @level2
      flash[:notice].should_not be_nil
    end
  end
  

end
