require "rails_helper"
require 'product_shared_examples'

RSpec.describe Service do

  context "factory" do
    it "should create using factory" do
      @facility     = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @order_status = FactoryGirl.create(:order_status)
      @service      = @facility.services.create(FactoryGirl.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      expect(@service).to be_valid
      expect(@service.type).to eq('Service')
    end
  end

  it "should validate presence of initial_order_status_id" do
    is_expected.to validate_presence_of(:initial_order_status_id)
  end

  it_should_behave_like "NonReservationProduct", :service

end
