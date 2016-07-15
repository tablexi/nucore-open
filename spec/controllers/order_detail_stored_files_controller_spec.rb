require "rails_helper"

RSpec.describe OrderDetailStoredFilesController do
  let(:user) { order_detail.user }

  describe "#order_file" do
    let(:product) { create(:setup_service, :with_order_form) }
    let(:order_detail) { order.order_details.first }
    let(:facility) { order.facility }

    let(:params) { { order_id: order.id, order_detail_id: order_detail.id } }
    before { sign_in user }

    describe "while in the cart" do
      let(:order) { create(:setup_order, product: product) }

      it "has access" do
        get :order_file, params
        expect(response).to be_success
      end
    end

    describe "adding to an existing order" do
      let(:order) { create(:purchased_order, product: product) }
      let(:user) { create(:user, :staff, facility: facility) }
      let(:merge_order) { create(:merge_order, merge_with_order: order) }

      it "has access" do
        get :order_file, order_id: merge_order.id, order_detail_id: merge_order.order_details.first.id
        expect(response).to be_success
      end
    end
  end
end
