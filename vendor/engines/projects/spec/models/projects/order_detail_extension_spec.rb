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
end
