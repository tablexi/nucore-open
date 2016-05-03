require "rails_helper"

RSpec.describe Projects::OrderDetailExtension do
  subject(:order_detail) { FactoryGirl.build(:order_detail) }
  let(:project) { FactoryGirl.create(:project, facility: facility) }

  context "validations" do
    it "can belong_to a Project" do
      is_expected
        .to belong_to(:project)
        .with_foreign_key(:project_id)
        .inverse_of(:order_details)
    end

    describe "Facility scoping" do
      subject(:order_detail) { order.order_details.first }
      let(:item) { FactoryGirl.create(:setup_item) }
      let(:order) { FactoryGirl.create(:setup_order, product: item) }

      before { order_detail.update_attribute(:project_id, project.id) }

      context "when the Project belongs to the same facility as the OrderDetail" do
        let(:facility) { order_detail.facility }
        it { is_expected.to be_valid }
      end

      context "when the Project belongs to a different facility than the OrderDetail" do
        let(:facility) { FactoryGirl.create(:facility) }

        it "is invalid" do
          is_expected.not_to be_valid
          expect(order_detail.errors[:project_id])
            .to include("The project belongs to another facility")
        end
      end
    end
  end

  describe "#selectable_projects" do
    subject(:order_detail) { order.order_details.first }
    let(:facility) { order.facility }
    let(:item) { FactoryGirl.create(:setup_item) }
    let(:order) { FactoryGirl.create(:setup_order, product: item) }

    context "when there are no active projects for the associated facility" do
      before(:each) do
        FactoryGirl.create(:project, :inactive, facility: order_detail.facility)
      end

      it { expect(order_detail.selectable_projects).to be_empty }
    end

    context "when there are active projects for the associated facility" do
      let(:active_projects) { FactoryGirl.create_list(:project, 3, facility: facility) }
      let(:inactive_project) { FactoryGirl.create(:project, :inactive, facility: facility) }
      let!(:all_projects) { active_projects + [inactive_project] }

      before { order_detail.update_attribute(:project_id, project_id) }

      context "and the order_detail has an inactive project" do
        let(:project_id) { inactive_project.id }

        it "includes the inactive project in the list" do
          expect(order_detail.selectable_projects)
            .to match_array(active_projects + [inactive_project])
        end
      end

      context "and the order_detail has no project selected" do
        let(:project_id) { nil }

        it "returns all active projects for the facility" do
          expect(order_detail.selectable_projects)
            .to match_array(active_projects)
        end
      end

      context "when the order_detail has an active project selected" do
        let(:project_id) { active_projects.first.id }

        it "returns all active projects for the facility" do
          expect(order_detail.selectable_projects)
            .to match_array(active_projects)
        end
      end
    end
  end
end
