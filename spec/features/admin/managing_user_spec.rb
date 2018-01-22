require "rails_helper"

RSpec.describe "Managing User Details", :aggregate_failures do

  let(:facility) { FactoryBot.create(:facility) }

  describe "edit" do
    describe "as a facility admin" do
      let(:admin) { FactoryBot.create(:user, :administrator) }
      let(:user) { FactoryBot.create(:user) }

      before do
        login_as admin
        visit facility_user_path(facility, user)
      end

      it "allows admin to edit internal/external pricing" do
        expect(page).to have_content("Internal PricingYes")

        click_link "Edit"

        select "No", from: "user_internal"

        click_button "Update"

        expect(page).to have_content("Internal PricingNo")
      end

    end

    describe "as an account admin" do
      let!(:account_admin) { FactoryBot.create(:user, :account_manager) }
      let!(:user) { FactoryBot.create(:user) }

      before do
        login_as account_admin
        visit facility_user_path(Facility.cross_facility, user)
      end

      it "does not allow account admin to edit internal/external pricing" do
        expect(page).to have_content("Internal PricingYes")

        click_link "Edit"

        expect(page).not_to have_content("Internal Pricing")
      end

    end

  end
end
