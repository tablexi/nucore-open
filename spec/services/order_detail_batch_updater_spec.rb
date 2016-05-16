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
    { assigned_user_id: assigned_user_id, order_status_id: order_status_id }
  end
  let(:user) { FactoryGirl.create(:user) }

  describe "#update!" do
    shared_examples_for "batch updating" do
      context "when assigned_user_id is already set" do
        before { order_detail.update_attribute(:assigned_user_id, 2) }

        context "and the assigned_user_id parameter is blank" do
          it "does not change the assigned_user_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(2)
          end

          it "returns a no-changes-required note" do
            expect(updater.update!).to eq(notice: "No changes were required")
          end
        end

        context "and the assigned_user_id parameter is a new value" do
          let(:assigned_user_id) { "1" }

          it "updates assigned_user_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.assigned_user_id }
              .from(2)
              .to(1)
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the assigned_user_id parameter is the same value" do
          let(:assigned_user_id) { "2" }

          it "does not change the assigned_user_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(2)
          end

          it "returns a successful update note (despite nothing changing)" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the assigned_user_id parameter is set to 'unassign'" do
          let(:assigned_user_id) { "unassign" }

          it "changes the assigned_user_id to nil" do
            expect { updater.update! }
              .to change { order_detail.reload.assigned_user_id }
              .from(2)
              .to(nil)
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end
      end

      context "when assigned_user_id is not set" do
        context "and the assigned_user_id parameter is blank" do
          it "does not change the assigned_user_id from nil" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(nil)
          end

          it "returns a no-changes-required note" do
            expect(updater.update!).to eq(notice: "No changes were required")
          end
        end

        context "and the assigned_user_id parameter is a new value" do
          let(:assigned_user_id) { "1" }

          it "updates assigned_user_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.assigned_user_id }
              .from(nil)
              .to(1)
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the assigned_user_id parameter is set to 'unassign'" do
          let(:assigned_user_id) { "unassign" }

          it "does not change the assigned_user_id from nil" do
            expect { updater.update! }
              .not_to change { order_detail.reload.assigned_user_id }
              .from(nil)
          end

          it "returns a successful update note (despite nothing changing)" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end
      end

      context "when order_status_id is already set" do
        before(:each) do
          order_detail.update_attribute(:order_status_id, 2)
        end

        context "and the order_status_id parameter is blank" do
          it "does not change the order_status_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.order_status_id }
              .from(2)
          end

          it "returns a no-changes-required note" do
            expect(updater.update!).to eq(notice: "No changes were required")
          end
        end

        context "and the order_status_id parameter is a new value" do
          let(:order_status_id) { "1" }

          it "updates order_status_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.order_status_id }
              .from(2)
              .to(1)
          end

          it "returns a successful update note" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end

        context "and the order_status_id parameter is the same value" do
          let(:order_status_id) { "2" }

          it "does not change the order_status_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.order_status_id }
              .from(2)
          end

          it "returns a successful update note (despite nothing changing)" do
            expect(updater.update!)
              .to eq(notice: "The #{record_type} were successfully updated")
          end
        end
      end

      context "when order_status_id is not set" do
        it { expect(updater.update!).to eq(notice: "No changes were required") }
      end
    end

    context "when associated with Orders" do
      let(:record_type) { "orders" }

      it_behaves_like "batch updating"
    end

    context "when associated with Reservations" do
      let(:record_type) { "reservations" }

      it_behaves_like "batch updating"
    end
  end
end
