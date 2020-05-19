# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing Price Groups", :aggregate_failures do

  let(:facility) { FactoryBot.create(:facility) }

  describe "create" do
    describe "as a facility admin", feature_setting: { facility_directors_can_manage_price_groups: true } do
      let(:user) { FactoryBot.create(:user, :facility_director, facility: facility) }

      before do
        login_as user
        visit facility_price_groups_path(facility)
        click_link "Add Price Group"
        fill_in "Name", with: "New Price Group"
        check "Is Internal?"
      end

      it "creates a price group and brings you back to the index" do
        expect { click_button "Create" }.to change(PriceGroup, :count).by(1)
        expect(current_path).to eq(accounts_facility_price_group_path(facility, PriceGroup.reorder(:id).last))
        log_event = LogEvent.find_by(loggable: price_group, event_type: :create)
        expect(log_event).to be_present
      end
    end

    describe "as a facility senior staff" do
      let(:user) { FactoryBot.create(:user, :senior_staff, facility: facility) }

      before do
        login_as user
        visit new_facility_price_group_path(facility)
      end

      it "does not allow access" do
        expect(page.status_code).to eq(403)
      end
    end
  end

  describe "destroy" do
    describe "as a facility admin", feature_setting: { facility_directors_can_manage_price_groups: true } do
      let(:user) { FactoryBot.create(:user, :facility_director, facility: facility) }
      let!(:price_group) { FactoryBot.create(:price_group, facility: facility) }

      before do
        login_as user
        visit facility_price_groups_path(facility)
      end

      it "deletes a price group and brings you back to the index" do
        expect { click_link "Remove" }.to change(PriceGroup, :count).by(-1)
        expect(current_path).to eq(facility_price_groups_path(facility))
        log_event = LogEvent.find_by(loggable: price_group, event_type: :delete)
        expect(log_event).to be_present
      end
    end

    describe "as a facility senior staff" do
      let(:user) { FactoryBot.create(:user, :senior_staff, facility: facility) }

      before do
        login_as user
        visit facility_price_groups_path(facility)
      end

      it "does not have a remove link present" do
        expect(page).not_to have_link("Remove")
      end
    end
  end


  # TODO: Move tests out of price_groups_controller_spec.rb
end
