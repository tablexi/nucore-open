require "rails_helper"

RSpec.describe Reports::GeneralReportsController do
  let(:facility) { item.facility }
  let(:item) { FactoryGirl.create(:setup_item) }
  let!(:order) { FactoryGirl.create(:purchased_order, product: item, ordered_at: 1.month.ago) }
  let!(:no_project_order) { FactoryGirl.create(:purchased_order, product: item) }
  let(:project) { FactoryGirl.create(:project, facility: facility) }
  let(:administrator) { FactoryGirl.create(:user, :administrator) }

  describe "the project report" do
    before do
      order.order_details.first.update_attributes!(project_id: project.id)
      sign_in administrator
      xhr :get, :index, report_by: :project, date_start: 2.months.ago, date_end: Time.current,
                        status_filter: [OrderStatus.new_status], facility_id: facility.url_name, date_range_field: "ordered_at"
    end

    describe "the project row" do
      let(:row) { assigns[:rows].second }

      it "has the proper data" do
        expect(row.length).to eq(4)
        expect(row.first.to_s).to eq(project.name)
      end
    end

    describe "the non-project row" do
      let(:row) { assigns[:rows].first }
      it "has the proper data" do
        expect(row.length).to eq(4)
        expect(row.first.to_s).to eq(" No Project")
      end
    end
  end
end
