require "rails_helper"

RSpec.describe OrdersController do
  let(:item) { FactoryGirl.create(:setup_item) }
  let(:order) { FactoryGirl.create(:setup_order, product: item) }
  let(:project_id) { FactoryGirl.create(:project, facility: order.facility).id }
  let(:administrator) { FactoryGirl.create(:user, :administrator) }

  before { sign_in administrator }

  def perform_request
    put action, id: order.id, order: order_params
    order.reload
  end

  shared_examples_for "it updates project_ids" do
    context "when purchasing on behalf of another user (acting_as)" do
      before(:each) do
        session[:acting_user_id] = order.user.id
        perform_request
      end

      context "when sending a project_id parameter" do
        let(:order_params) { { project_id: project_id } }

        it "sets the project_id" do
          expect(order.project_id).to eq(project_id)

          order.order_details.each do |order_detail|
            expect(order_detail.project_id). to eq(project_id)
          end
        end
      end

      context "when sending no project_id parameter" do
        let(:order_params) { {} }

        it "has no project_id" do
          expect(order.project_id).to be_blank

          order.order_details.each do |order_detail|
            expect(order_detail.project_id). to be_blank
          end
        end
      end
    end

    context "when not acting_as another user" do
      before { perform_request }

      context "when sending a project_id parameter" do
        let(:order_params) { { project_id: project_id } }

        it "has no project_id" do
          expect(order.project_id).to be_blank

          order.order_details.each do |order_detail|
            expect(order_detail.project_id). to be_blank
          end
        end
      end
    end
  end

  describe "PUT #purchase" do
    let(:action) { :purchase }

    it_behaves_like "it updates project_ids"
  end

  describe "PUT #update" do
    let(:action) { :update }

    it_behaves_like "it updates project_ids"
  end
end
