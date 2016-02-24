require "rails_helper"

RSpec.describe Reports::AccountTransactionsReport do
  subject(:report) { Reports::AccountTransactionsReport.new(order_details) }

  describe '#to_csv' do
    context "with no order details" do
      # TODO: use `.none` in Rails 4
      let(:order_details) { OrderDetail.where("1 = 0") }

      it "generates a header" do
        expect(report.to_csv.lines.count).to eq(1)
      end
    end

    context "with one order detail" do
      let!(:order_detail) { create(:purchased_reservation).order_detail }
      let(:order_details) { OrderDetail }

      it "generates an order detail line" do
        expect(report.to_csv.lines.count).to eq(2)
      end
    end
  end
end
