# frozen_string_literal: true

require "rails_helper"
require "product_shared_examples"

RSpec.describe Service do

  context "factory" do
    it "can create using a factory" do
      @facility = FactoryBot.create(:facility)
      @facility_account = FactoryBot.create(:facility_account, facility: @facility)
      @order_status = FactoryBot.create(:order_status)
      @service      = @facility.services.create(FactoryBot.attributes_for(:service, initial_order_status_id: @order_status.id, facility_account_id: @facility_account.id))
      expect(@service).to be_valid
      expect(@service.type).to eq("Service")
    end
  end

  it "validates presence of initial_order_status_id" do
    is_expected.to validate_presence_of(:initial_order_status_id)
  end

  it_should_behave_like "NonReservationProduct", :service

end
