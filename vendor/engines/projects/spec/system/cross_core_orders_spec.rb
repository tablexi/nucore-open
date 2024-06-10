# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cross Core Orders", :js, feature_setting: { cross_core_order_view: true } do
  # Facility 1 has cross core orders with Facility 2 but NOT Facility 3
  # This is the "Current Facility"
  let(:facility) { create(:setup_facility) }
  let(:facility_administrator) { create(:user, :facility_administrator, facility:) }
  let(:item) { create(:setup_item, facility:) }
  let(:item2) { create(:setup_item, facility:) }
  let(:accounts) { create_list(:setup_account, 2) }
  let!(:originating_order_facility1) { create(:purchased_order, product: item, account: accounts.first, cross_core_project:) }
  let!(:not_a_cross_core_order_facility1) { create(:purchased_order, product: item, account: accounts.first) }

  # Facility 2 has cross core orders with both Facility 1 and Facility 3
  let(:facility2) { create(:setup_facility) }
  let(:facility2_item) { create(:setup_item, facility: facility2) }
  let(:facility2_item2) { create(:setup_item, facility: facility2) }
  let!(:originating_order_facility2) { create(:purchased_order, product: facility2_item, account: accounts.first, cross_core_project: cross_core_project2) }

  # Facility 3 has cross core orders ONLY with Facility 2
  let(:facility3) { create(:setup_facility) }
  let(:facility3_item) { create(:setup_item, facility: facility3) }
  let!(:originating_order_facility3) { create(:purchased_order, product: facility3_item, account: accounts.first, cross_core_project: cross_core_project3) }

  # Create the cross core project records
  let(:cross_core_project) { create(:project, facility:, name: "#{facility.abbreviation}-1") }
  let(:cross_core_project2) { create(:project, facility: facility2, name: "#{facility2.abbreviation}-2") }
  let(:cross_core_project3) { create(:project, facility: facility3, name: "#{facility3.abbreviation}-3") }

  # Create the cross core orders and add them to the relevant projcects
  let!(:cross_core_orders) do
    [
      create(:purchased_order, cross_core_project:, product: facility2_item, account: accounts.last),
      create(:purchased_order, cross_core_project:, product: facility3_item, account: accounts.last),
      create(:purchased_order, cross_core_project: cross_core_project2, product: item, account: accounts.last),
      create(:purchased_order, cross_core_project: cross_core_project2, product: facility3_item, account: accounts.last),
      # cross_core_project3 has no order details from facility 1
      create(:purchased_order, cross_core_project: cross_core_project3, product: facility2_item2, account: accounts.last),
    ]
  end

  before do
    login_as facility_administrator

    visit cross_core_orders_facility_projects_path(facility)
  end

  it "shows no icons" do
    expect(page).to have_css(".fa-users", count: 0)
    expect(page).to have_css(".fa-building", count: 0)
  end

  context "when selecting Other - default" do
    it "shows all cross core orders placed for other facilities" do
      expect(page).to have_content(cross_core_orders[0].order_details.first)
      expect(page).to have_content(cross_core_orders[1].order_details.first)
      expect(page).to have_content(cross_core_orders[3].order_details.first)
      expect(page).to have_content(originating_order_facility2.order_details.first)

      expect(page).not_to have_content(cross_core_orders[2].order_details.first)
      expect(page).not_to have_content(originating_order_facility1.order_details.first)
    end
  end

  context "when selecting All" do
    before do
      select "All", from: "Participating #{I18n.t("facilities_downcase")}"
      click_button "Filter"
    end

    it "shows all cross core orders related to the current facility" do
      expect(page).to have_content(cross_core_orders[0].order_details.first)
      expect(page).to have_content(cross_core_orders[1].order_details.first)
      expect(page).to have_content(cross_core_orders[2].order_details.first)
      expect(page).to have_content(cross_core_orders[3].order_details.first)
      # This is from a cross core order that is not related to facility 1
      expect(page).not_to have_content(cross_core_orders[4].order_details.first)

      expect(page).to have_content(originating_order_facility2.order_details.first)
      expect(page).to have_content(originating_order_facility1.order_details.first)

      item_price_group = item.price_policies.first.price_group.name
      facility2_item_price_group = facility2_item.price_policies.first.price_group.name
      facility3_item_price_group = facility3_item.price_policies.first.price_group.name

      expect(page).to have_content(item_price_group, count: 2)
      expect(page).to have_content(facility2_item_price_group, count: 2)
      expect(page).to have_content(facility3_item_price_group, count: 2)
    end
  end

  context "when selecting Current" do
    before do
      select "Current", from: "Participating #{I18n.t("facilities_downcase")}"
      click_button "Filter"
    end

    it "shows only cross core orders placed for current facility" do
      expect(page).to have_content(cross_core_orders[2].order_details.first)
      expect(page).to have_content(originating_order_facility1.order_details.first)

      expect(page).not_to have_content(cross_core_orders[0].order_details.first)
      expect(page).not_to have_content(cross_core_orders[1].order_details.first)
      expect(page).not_to have_content(cross_core_orders[3].order_details.first)
      expect(page).not_to have_content(originating_order_facility2.order_details.first)
    end
  end
end
