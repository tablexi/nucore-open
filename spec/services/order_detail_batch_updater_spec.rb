require "rails_helper"

# TODO: These specs are incomplete and document existing behavior

RSpec.describe OrderDetailBatchUpdater do
  subject(:updater) do
    described_class.new(
      [order_detail.id],
      facility,
      user,
      params,
      record_type,
    )
  end

  let(:assigned_user_id) { "" }
  let(:facility) { order.facility }
  let(:item) { FactoryGirl.create(:setup_item) }
  let(:order) { FactoryGirl.create(:purchased_order, product: item) }
  let(:order_detail) { order.order_details.first }
  let(:order_status_id) { "" }
  let(:params) do
    {
      assigned_user_id: assigned_user_id,
      order_status_id: order_status_id,
    }
  end
  let(:user) { FactoryGirl.create(:user) }

  describe "#update!" do
    context "when associated with Orders" do
      let(:record_type) { "orders" }

      context "when assigned_user_id is set" do
        let(:assigned_user_id) { "1" }

        context "to the same value it was" do
          before(:each) do
            order_detail.update_attribute(:assigned_user_id, assigned_user_id)
          end

          it "does not change the assigned_user_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(1)
          end

          it "returns a successful update note (despite nothing changing)" do
            expect(updater.update!)
              .to eq(notice: "The orders were successfully updated")
          end
        end

        context "to a new value" do
          it "updates the assigned_user_id" do
            expect { updater.update! }
              .to change { order_detail.reload.assigned_user_id }
              .from(nil)
              .to(1)
          end
        end

        it "returns a successful update note" do
          expect(updater.update!)
            .to eq(notice: "The orders were successfully updated")
        end
      end

      context "when assigned_user_id is blank" do
        before { order_detail.update_attribute(:assigned_user_id, 1) }

        it "does not change the assigned_user_id" do
          expect { updater.update! }
            .not_to change { order_detail.reload.assigned_user_id }
            .from(1)
        end

        it { expect(updater.update!).to eq(notice: "No changes were required") }
      end

      context "when order_status_id is set" do
        let(:order_status_id) { "1" }
      end

      context "when order_status_id is blank" do
        it { expect(updater.update!).to eq(notice: "No changes were required") }
      end
    end

    context "when associated with Reservations" do
      let(:record_type) { "reservations" }
    end
  end
end
