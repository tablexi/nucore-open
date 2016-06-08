require "rails_helper"

RSpec.describe "Sanger Sequencing Administration" do
  let(:facility) { FactoryGirl.create(:facility, sanger_sequencing_enabled: true) }

  describe "as the facility director" do
    let(:facility_director) { FactoryGirl.create(:user, :facility_director, facility: facility) }

    before { login_as facility_director }

    it "can access the tab" do
      visit list_facilities_path
      click_link facility.name
      click_link "Sanger"
      expect(page).to have_content "Welcome to Sanger Sequencing"
    end
  end
end
