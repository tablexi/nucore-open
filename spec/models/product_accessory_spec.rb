# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductAccessory do

  before(:each) { create :accessory }

  let(:accessory) { ProductAccessory.first }

  it "updates deleted_at but does not destroy" do
    expect(accessory.deleted_at).to be_nil
    accessory.soft_delete
    expect(accessory.deleted_at).to be_present
    expect(accessory).to_not be_frozen
  end

  it "is not deleted" do
    expect(accessory).to_not be_deleted
  end

  it "is deleted" do
    accessory.soft_delete
    expect(accessory).to be_deleted
  end
end
