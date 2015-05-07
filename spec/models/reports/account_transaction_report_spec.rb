require 'spec_helper'

describe Reports::AccountTransactionsReport do
  subject(:report) { Reports::AccountTransactionsReport.new(order_details) }

  describe '#to_csv' do
    context 'with no order details' do
      let(:order_details) { [] }

      it 'generates a header' do
        expect(report.to_csv.lines.count).to eq(1)
      end
    end

    context 'with one order detail' do
      let(:order_details) { [create(:purchased_reservation).order_detail] }

      it 'generates an order detail line' do
        expect(report.to_csv.lines.count).to eq(2)
      end
    end
  end
end
