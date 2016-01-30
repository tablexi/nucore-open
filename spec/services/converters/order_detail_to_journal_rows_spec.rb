require "rails_helper"

RSpec.describe Converters::OrderDetailToJournalRowAttributes, type: :service do

  let(:converter) { described_class.new(journal, order_detail) }
  let(:journal) { build_stubbed(:journal) }
  let(:order_detail) do
    build_stubbed(:order_detail).tap do |order_detail|
      allow(order_detail).to receive_message_chain(:product, :account) { "product_account" }
      allow(order_detail).to receive(:total) { 100 }
      allow(order_detail).to receive(:long_description) { "long_description" }
    end
  end

  it "initializes journal" do
    expect(converter.journal).to eq(journal)
  end

  it "initializes order_detail" do
    expect(converter.order_detail).to eq(order_detail)
  end

  describe "#convert" do
    let(:returned) { converter.convert }

    it "returns one journal row" do
      expect(returned.size).to eq(1)
    end

    context "for first journal row" do
      let(:row) { returned.first }

      it "sets account" do
        expect(row[:account]).to eq(order_detail.product.account)
      end

      it "sets amount" do
        expect(row[:amount]).to eq(order_detail.total)
      end

      it "sets description" do
        expect(row[:description]).to eq(order_detail.long_description)
      end

      it "sets order_detail_id" do
        expect(row[:order_detail_id]).to eq(order_detail.id)
      end

      it "sets journal_id" do
        expect(row[:journal_id]).to eq(journal.id)
      end
    end
  end

end
