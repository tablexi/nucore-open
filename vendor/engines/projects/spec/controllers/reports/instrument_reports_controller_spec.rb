require "rails_helper"

RSpec.describe Reports::InstrumentReportsController do
  let(:facility) { FactoryGirl.create(:setup_facility) }
  let(:instrument) { FactoryGirl.create(:setup_instrument, facility: facility) }
  let!(:reservation) { FactoryGirl.create(:completed_reservation, product: instrument) }
  let!(:no_project_reservation) { FactoryGirl.create(:completed_reservation, product: instrument) }
  let(:order_detail) { reservation.order_detail }
  let(:project) { FactoryGirl.create(:project, facility: facility) }
  let(:user) { FactoryGirl.create(:user, :facility_director, facility: facility) }

  describe "the project report" do
    before do
      order_detail.update_attributes(project: project)
      sign_in user
      xhr :get, :index, report_by: :project, facility_id: facility.url_name,
                        date_start: 1.month.ago, date_end: Time.current
    end

    describe "the project row" do
      let(:row) { assigns[:rows].second }

      it "has the proper data" do
        expect(row.length).to eq(7)
        expect(row.first(3)).to eq([instrument.name, project.name, "1"])
      end
    end

    describe "the non-project row" do
      let(:row) { assigns[:rows].first }

      it "has the proper data" do
        expect(row.length).to eq(7)
        expect(row.first(3)).to eq([instrument.name, " No Project", "1"])
      end
    end
  end
end
