require "rails_helper"

RSpec.describe Projects::OrderExtension do
  subject(:order) { FactoryGirl.create(:setup_order, product: item) }
  let(:item) { FactoryGirl.create(:setup_item) }
  let(:project_id) { FactoryGirl.create(:project, facility: order.facility).id }

  describe "#project_id" do
    context "when none of its order_details has a project" do
      it { expect(order.project_id).to be_blank }
    end

    context "when at least one of its order_details has a project" do
      let(:order_detail) { order.order_details.last }

      before { order_detail.update_attribute(:project_id, project_id) }

      it { expect(order.project_id).to eq(project_id) }
    end
  end

  describe "#project_id=" do
    before(:each) do
      order.project_id = project_id
      order.save
    end

    context "when setting it to nil" do
      let(:project_id) { nil }

      it "sets the project_id on its order_details to nil on #save" do
        order.order_details.each do |order_detail|
          expect(order_detail.project_id).to be_blank
        end
      end
    end

    context "when setting it to a project_id" do
      context "that is valid for the facility" do
        it "sets this project_id on its order_details on #save" do
          order.order_details.each do |order_detail|
            expect(order_detail.project_id).to eq(project_id)
          end
        end
      end

      context "that is invalid for the facility" do
        let(:project_id) { FactoryGirl.create(:project).id }

        it "fails to set project_id on the order_details" do
          order.reload.order_details.each do |order_detail|
            expect(order_detail.project_id).to be_blank
          end
        end
      end
    end
  end
end
