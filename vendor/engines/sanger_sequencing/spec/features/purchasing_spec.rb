require "rails_helper"

RSpec.describe "Purchasing a Sanger Sequencing service", :aggregate_failures do
  include RSpec::Matchers.clone # Give RSpec's `all` precedence over Capybara's

  let!(:service) { FactoryGirl.create(:setup_service) }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { service.facility }
  let!(:price_policy) { FactoryGirl.create(:service_price_policy, price_group: PriceGroup.base.first, product: service) }
  let(:user) { FactoryGirl.create(:user) }
  let(:external_service) { create(:external_service, location: new_sanger_sequencing_submission_path) }
  let!(:sanger_order_form) { create(:external_service_passer, external_service: external_service, active: true, passer: service) }

  before do
    login_as user
  end

  describe "submission form" do
    let(:quantity) { 5 }
    let(:customer_id_selector) { ".edit_sanger_sequencing_submission input[type=text]" }
    before do
      visit facility_service_path(facility, service)
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
      find(".edit_order input[type=text]").set(quantity.to_s)
      click_button "Update"
      click_link "Complete Online Order Form"
    end

    it "sets up the right number of text boxes" do
      expect(page).to have_css(customer_id_selector, count: 5)
    end

    it "has prefilled values in the text boxes with unique four digit numbers" do
      values = page.all(customer_id_selector).map(&:value)
      expect(values).to all(match(/\A\d{4}\z/))
      expect(values.uniq).to eq(values)
    end

    it "saves the form" do
      page.first(customer_id_selector).set("TEST123")
      click_button "Save Submission"
      expect(SangerSequencing::Sample.pluck(:customer_sample_id)).to include("TEST123")
      expect(SangerSequencing::Sample.count).to eq(5)
    end

    describe "blank fields" do
      it "does not allow submitting a blank value" do
        page.first(customer_id_selector).set("")
        click_button "Save Submission"
        expect(page.first(customer_id_selector).value).to be_blank
        expect(SangerSequencing::Sample.pluck(:customer_sample_id)).not_to include("")
      end

      it "deletes blanks from the end" do
        page.all(customer_id_selector).last.set("")
        click_button "Save Submission"
        expect(SangerSequencing::Sample.count).to eq(4)
      end

      it "does not delete blanks on invalid" do
        page.first(customer_id_selector).set("")
        page.all(customer_id_selector)[-2].set("")
        page.all(customer_id_selector).last.set("")
        click_button "Save Submission"
        expect(page.first(customer_id_selector).value).to be_blank
        expect(page.all(customer_id_selector).last.value).to be_blank
        expect(page).to have_css(customer_id_selector, count: 5)
        expect(SangerSequencing::Sample.pluck(:customer_sample_id)).not_to include("")
      end

      it "does not save if they are all blank" do
        page.all(customer_id_selector).each { |textbox| textbox.set("") }
        click_button "Save Submission"
        expect(page).to have_css(customer_id_selector, count: 5)
        expect(page.all(customer_id_selector).map(&:value)).to all(be_blank)
      end
    end
  end
end
