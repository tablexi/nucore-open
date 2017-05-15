RSpec.shared_context "Setup Sanger Service" do
  let(:facility) { FactoryGirl.create(:setup_facility, sanger_sequencing_enabled: true) }
  let!(:service) { FactoryGirl.create(:setup_service, facility: facility) }
  let(:purchaser) { FactoryGirl.create(:user) }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: purchaser) }
  let!(:price_policy) { FactoryGirl.create(:service_price_policy, price_group: PriceGroup.base, product: service) }
  let(:facility_staff) { FactoryGirl.create(:user, :staff, facility: facility) }
end
