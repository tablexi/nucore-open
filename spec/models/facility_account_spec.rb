# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityAccount do
  describe "#revenue_account" do
    it "is an integer" do
      is_expected.to validate_numericality_of(:revenue_account).only_integer
    end
  end
end
