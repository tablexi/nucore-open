require "rails_helper"

RSpec.describe FacilitiesController do
  describe "#transactions" do
    let(:facility) { FactoryGirl.create(:setup_facility) }
    let(:product) { FactoryGirl.create(:setup_item, facility: facility) }
    let(:project) { FactoryGirl.create(:project, facility: facility) }
    let(:order) { FactoryGirl.create(:purchased_order, product: product) }
    let(:order_detail) { order.order_details.first }
    let(:order2) { FactoryGirl.create(:purchased_order, product: product) }
    let(:order_detail2) { order2.order_details.first }

    let(:admin) { FactoryGirl.create(:user, :administrator) }

    before do
      order_detail.update_attributes(project: project)
      sign_in admin
    end

    it "returns both order details with no filter" do
      get :transactions, facility_id: facility.url_name, projects: [], date_range: { field: "ordered_at" }
      expect(assigns(:order_details)).to contain_all([order_detail, order_detail2])
    end

    it "returns only the order detail selected" do
      get :transactions, facility_id: facility.url_name, projects: [project.id], date_range: { field: "ordered_at" }
      expect(assigns(:order_details)).to eq([order_detail])
    end

    it "includes the projects" do
      get :transactions, facility_id: facility.url_name
      expect(assigns(:search_options)[:projects]).to eq([project])
    end
  end
end
