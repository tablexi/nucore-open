require "rails_helper"

RSpec.describe "Sanger Sequencing Administration" do
  let(:facility) { FactoryGirl.create(:setup_facility, sanger_sequencing_enabled: true) }
  let!(:service) { FactoryGirl.create(:setup_service, facility: facility) }
  let(:purchaser) { FactoryGirl.create(:user) }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: purchaser) }
  let!(:price_policy) { FactoryGirl.create(:service_price_policy, price_group: PriceGroup.base.first, product: service) }

  describe "as facility staff" do
    let(:facility_staff) { FactoryGirl.create(:user, :staff, facility: facility) }

    before { login_as facility_staff }

    describe "index view" do
      let!(:unpurchased_order) { FactoryGirl.create(:setup_order, product: service, account: account) }
      let!(:unpurchased_submission) { FactoryGirl.create(:sanger_sequencing_submission, order_detail: unpurchased_order.order_details.first) }
      let!(:purchased_order) { FactoryGirl.create(:purchased_order, product: service, account: account) }
      let!(:purchased_submission) { FactoryGirl.create(:sanger_sequencing_submission, order_detail: purchased_order.order_details.first) }

      before do
        visit list_facilities_path
        click_link facility.name
        click_link "Sanger"
      end

      it "has only the purchased submission" do
        expect(page).to have_link(purchased_order.order_details.first.to_s)
        expect(page).not_to have_link(unpurchased_order.order_details.first.to_s)
      end

      describe "clicking through to show" do
        before do
          purchased_submission.samples.create(customer_sample_id: "TESTING 123")
          click_link purchased_submission.id
        end

        it "has the sample on the page" do
          expect(page).to have_content("TESTING 123")
        end
      end

      describe "attempting to access an unpurchased submission" do
        before { visit facility_sanger_sequencing_admin_submission_path(facility, unpurchased_submission) }

        it "is not found" do
          expect(page.status_code).to eq(404)
        end
      end
    end
  end

  describe "as a member of another facility" do
    let(:facility2) { FactoryGirl.create(:facility) }
    let(:other_user) { FactoryGirl.create(:user, :staff, facility: facility2) }

    before { login_as other_user }

    it "does not have access" do
      visit facility_sanger_sequencing_admin_submissions_path(facility)
      expect(page.status_code).to eq(403)
    end
  end
end
