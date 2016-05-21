require "rails_helper"

RSpec.describe "Purchasing a Sanger Sequencing service" do
  let!(:service) { FactoryGirl.create(:setup_service) }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { service.facility }
  let!(:price_policy) { FactoryGirl.create(:service_price_policy, price_group: PriceGroup.base.first, product: service) }
  let(:user) { FactoryGirl.create(:user) }
  let(:external_service) { create(:external_service, location: SangerSequencing::Engine.routes.url_helpers.new_submission_path) }
  let!(:sanger_order_form) { create(:external_service_passer, external_service: external_service, active: true, passer: service) }

  before do
    login_as user
  end

  it "can access" do
    visit facility_service_path(facility, service)
    click_link "Add to cart"
    choose account.to_s
    click_button "Continue"
    click_link "Complete Online Order Form"
    expect(page).to have_content "Quantity: 1"
  end
end
