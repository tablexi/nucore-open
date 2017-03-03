require "rails_helper"

RSpec.describe "User's Indala Number" do
  let(:facility) { FactoryGirl.create(:facility) }
  let(:indala_user) { FactoryGirl.create(:user) }
  let(:staff_user) { FactoryGirl.create(:user, :staff, facility: facility) }

  describe "update" do
    before do
      login_as staff_user
      visit facility_user_path(facility, indala_user)
      click_link "Update"
      fill_in "Indala number", with: "123456"
      click_button "Update"
    end

    it "successfully updates the indala number" do
      expect(indala_user.reload.indala_number).to eq "123456"
    end
  end
end
