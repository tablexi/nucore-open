# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User access list" do
  describe "as facility director" do
    let(:facility) { FactoryBot.create(:setup_facility) }
    let(:admin) { create(:user, :facility_administrator, facility: facility) }
    let(:user) { create(:user) }
    let!(:product1) { create(:item, facility: facility, requires_approval: true) }
    let!(:product2) { create(:item, facility: facility, requires_approval: true) }
    let!(:product_user) { create(:product_user, user: user, product: product1)}

    it "can approve access to a product" do
      login_as admin
      visit facility_user_path(facility, user)
      click_on "Access List"
      save_and_open_page
      check "#{product2.name}"
    end
  end
  
end
