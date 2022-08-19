# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityAccount do
  describe "#revenue_account" do
    it "is required" do
      facility_account = build(:facility_account, revenue_account: nil)
      expect(facility_account.valid?).to be false
      expect(facility_account.errors[:revenue_account]).to include("may not be blank")
    end
  end
end
