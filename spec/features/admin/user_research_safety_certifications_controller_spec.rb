require "rails_helper"

RSpec.describe "Viewing a user's safety certifications" do
  let(:user) { FactoryBot.create(:user) }
  let!(:certificate_a) { FactoryBot.create(:research_safety_certificate) }
  let!(:certificate_b) { FactoryBot.create(:research_safety_certificate) }
  let(:facility) { FactoryBot.create(:facility) }
  let(:admin) { FactoryBot.create(:user, :facility_director, facility: facility) }

  before do
    login_as admin

    expect(ResearchSafetyCertificationLookup).to receive(:certified?).with(user, certificate_a).and_return(true)
    expect(ResearchSafetyCertificationLookup).to receive(:certified?).with(user, certificate_b).and_return(false)
  end

  it "can see the user's certifications" do
    visit facility_user_path(facility, user)
    click_link "Certifications"
    expect(page).to have_selector("li.muted", text: certificate_b.name)
    expect(page).to have_selector("li:not(.muted)", text: certificate_a.name)
  end
end
