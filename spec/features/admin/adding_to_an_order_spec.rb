require "rails_helper"

RSpec.describe "Adding to an existing order" do
  let(:facility) { item.facility }
  let(:item) { create(:setup_item, :with_facility_account) }
  let(:order) { create(:purchased_order, product: item) }
  let(:user) { create(:user, :staff, facility: facility) }

  before do
    login_as user
    visit facility_order_path(facility, order)
  end

  describe "adding an item" do
    before do
      fill_in "product_add_quantity", with: "2"
      select item.name, from: "product_add"
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
      before do
        select "Complete", from: "order_status_id"
        fill_in "fulfilled_at", with: "10/14/2016"
        click_button "Add To Order"
      end

      it "has a new order detail with the right status and fulfilled_at" do
        expect(order.reload.order_details.count).to be(2)
        expect(order.order_details.last).to be_complete
        # TODO cannot be before previous fiscal year
        expect(I18n.l(order.order_details.last.fulfilled_at, :usa)).to eq("10/14/2016")
      end
    end
  end


  # TODO: Adding a service with an order form
  # TODO: Adding an instrument

end
