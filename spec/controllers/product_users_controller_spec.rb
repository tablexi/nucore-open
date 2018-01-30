require "rails_helper"
require "controller_spec_helper"

RSpec.describe ProductUsersController do
  render_views

  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, facility: facility, requires_approval: true) }
  let(:guest) { create(:user) }
  let(:admin) { create(:user, :administrator) }
  let(:staff) { create(:user, :staff, facility: facility) }

  describe "index" do
    let!(:guest_product) { ProductUser.create(product: instrument, user: guest, approved_by: admin.id, approved_at: Time.current) }
    let!(:staff_product) { ProductUser.create(product: instrument, user: staff, approved_by: admin.id, approved_at: Time.current) }

    def do_request
      get :index, facility_id: facility.url_name, instrument_id: instrument.url_name
    end

    it "should only return the two users" do
      sign_in admin
      do_request
      expect(assigns[:product_users]).to eq([guest_product, staff_product])
    end

    it "should return empty and a flash if the product is not restricted" do
      instrument.update_attributes!(requires_approval: false)
      sign_in admin
      do_request

      expect(assigns[:product_users]).to be_nil
      expect(flash[:notice]).not_to be_empty
    end

  end

  describe "update_restrictions" do
    let(:level) { create(:product_access_group, product: instrument) }
    let(:level2) { create(:product_access_group, product: instrument) }

    let!(:guest_product) { create(:product_user, product: instrument, user: guest, approved_by_user: admin) }
    let!(:staff_product) { create(:product_user, product: instrument, user: staff, approved_by_user: admin) }

    it "updates the product_users" do
      sign_in staff
      put :update_restrictions, {
        facility_id: facility.url_name,
        instrument_id: instrument.url_name,
        instrument: {
          product_users: {
            guest_product.id => { product_access_group_id: level.id },
            staff_product.id => { product_access_group_id: level2.id },
          },
        },
      }

      expect(guest_product.reload.product_access_group).to eq(level)
      expect(staff_product.reload.product_access_group).to eq(level2)
      expect(flash[:notice]).to be_present
    end
  end
end
