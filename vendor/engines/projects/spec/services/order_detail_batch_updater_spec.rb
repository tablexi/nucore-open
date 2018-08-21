# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailBatchUpdater do
  subject(:updater) do
    described_class.new(
      [order_detail.id],
      facility,
      user,
      { project_id: project_id },
      record_type,
    )
  end

  let(:facility) { order.facility }
  let(:item) { FactoryBot.create(:setup_item) }
  let(:order) { FactoryBot.create(:purchased_order, product: item) }
  let(:order_detail) { order.order_details.first }
  let(:user) { FactoryBot.create(:user) }

  describe "#update!" do
    shared_examples_for "batch updating project_id" do
      let(:other_project) { FactoryBot.create(:project, facility: facility) }

      context "when project_id is already set" do
        let(:existing_project) { FactoryBot.create(:project, facility: facility) }

        before { order_detail.update_attribute(:project_id, existing_project.id) }

        context "and the project_id parameter is blank" do
          let(:project_id) { "" }

          it "does not change the project_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.project_id }
              .from(existing_project.id)
          end
        end

        context "and the project_id parameter is a new value" do
          let(:project_id) { other_project.id }

          it "changes the project_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.project_id }
              .from(existing_project.id)
              .to(other_project.id)
          end
        end

        context "and the project_id parameter is the same value" do
          let(:project_id) { existing_project.id }

          it "does not change the project_id" do
            expect { updater.update! }
              .not_to change { order_detail.reload.project_id }
              .from(existing_project.id)
          end
        end

        context "and the project_id parameter is set to 'unassign'" do
          let(:project_id) { "unassign" }

          it "changes the project_id to nil" do
            expect { updater.update! }
              .to change { order_detail.reload.project_id }
              .from(existing_project.id)
              .to(nil)
          end
        end
      end

      context "when project_id is not set" do
        context "and the project_id parameter is blank" do
          let(:project_id) { "" }

          it "does not change the project_id from nil" do
            expect { updater.update! }
              .not_to change { order_detail.reload.project_id }
              .from(nil)
          end
        end

        context "and the project_id parameter is a new value" do
          let(:project_id) { other_project.id }

          it "updates project_id to the new value" do
            expect { updater.update! }
              .to change { order_detail.reload.project_id }
              .from(nil)
              .to(other_project.id)
          end
        end

        context "and the project_id parameter is set to 'unassign'" do
          let(:project_id) { "unassign" }

          it "does not change the project_id from nil" do
            expect { updater.update! }
              .not_to change { order_detail.reload.project_id }
              .from(nil)
          end
        end
      end
    end

    context "when associated with Orders" do
      let(:record_type) { "orders" }

      it_behaves_like "batch updating project_id"
    end

    context "when associated with Reservations" do
      let(:record_type) { "Reservations" }

      it_behaves_like "batch updating project_id"
    end
  end
end
