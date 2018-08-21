# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding to an existing order" do
  let(:facility) { product.facility }
  let(:order) { create(:purchased_order, product: product) }
  let(:user) { create(:user, :staff, facility: facility) }

  before do
    login_as user
  end

  describe "adding an item" do
    let(:product) { create(:setup_item, :with_facility_account) }

    before do
      visit facility_order_path(facility, order)

      fill_in "product_add_quantity", with: "2"
      select product.name, from: "product_add"
      fill_in "Note", with: "My Note"
    end

    describe "adding it as New" do
      before do
        click_button "Add To Order"
      end

      it "has a new order detail" do
        expect(order.reload.order_details.count).to be(2)
        expect(order.order_details.last.note).to eq("My Note")
      end
    end

    describe "adding it as Complete" do
      let(:fulfilled_at_string) { I18n.l(1.day.ago.to_date, format: :usa) }

      before do
        select "Complete", from: "order_status_id"
        fill_in "fulfilled_at", with: fulfilled_at_string
        click_button "Add To Order"
      end

      it "has a new order detail with the right status and fulfilled_at" do
        expect(order.reload.order_details.count).to be(2)
        expect(order.order_details.last).to be_complete
        expect(I18n.l(order.order_details.last.fulfilled_at.to_date, format: :usa)).to eq(fulfilled_at_string)
      end
    end
  end

  describe "adding a backdated service with an order form" do
    let(:product) { create(:setup_service, :with_facility_account, :with_order_form) }
    let(:fulfilled_at_string) { I18n.l(1.day.ago.to_date, format: :usa) }

    before do
      visit facility_order_path(facility, order)

      fill_in "product_add_quantity", with: "1"
      select product.name, from: "product_add"
      select "Complete", from: "order_status_id"
      fill_in "fulfilled_at", with: fulfilled_at_string
      click_button "Add To Order"
    end

    it "requires a file to be uploaded before adding to the order" do
      expect(page).to have_content("The following order details need your attention.")

      click_link "Upload Order Form"
      attach_file "stored_file[file]", Rails.root.join("spec", "files", "template1.txt")
      click_button "Upload"

      expect(order.reload.order_details.count).to be(2)
      expect(order.order_details.last).to be_complete
      expect(I18n.l(order.order_details.last.fulfilled_at.to_date, format: :usa)).to eq(fulfilled_at_string)
    end
  end

  describe "adding an instrument reservation" do
    let(:product) { create(:setup_item, :with_facility_account) }
    let!(:instrument) { create(:setup_instrument, facility: facility) }

    before do
      visit facility_order_path(facility, order)
      fill_in "product_add_quantity", with: "1"
      select instrument.name, from: "product_add"
      click_button "Add To Order"
    end

    it "requires a reservation to be set up before adding to the order" do
      expect(page).to have_content("The following order details need your attention.")

      click_link "Make a Reservation"
      click_button "Create"

      expect(order.reload.order_details.count).to be(2)
      expect(order.order_details.last.product).to eq(instrument)
    end
  end

  describe "adding a timed service" do
    let(:product) { create(:setup_timed_service, :with_facility_account) }

    before do
      visit facility_order_path(facility, order)
      select product.name, from: "product_add"
      fill_in "product_add_duration", with: "31"
      click_button "Add To Order"
    end

    it "has a new order detail with the proper quantity" do
      expect(order.reload.order_details.count).to be(2)
      expect(order.order_details.last.product).to eq(product)
      expect(order.order_details.last.quantity).to eq(31)
    end
  end

end
