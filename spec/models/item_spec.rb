# frozen_string_literal: true

require "rails_helper"
require "product_shared_examples"

RSpec.describe Item do
  it "can create using a factory" do
    facility = FactoryBot.create(:facility)
    facility_account = FactoryBot.create(:facility_account, facility: facility)
    item = FactoryBot.create(:item, facility: facility, facility_account: facility_account)
    expect(item).to be_valid
    expect(item.type).to eq("Item")
  end

  it_should_behave_like "NonReservationProduct", :item

end
