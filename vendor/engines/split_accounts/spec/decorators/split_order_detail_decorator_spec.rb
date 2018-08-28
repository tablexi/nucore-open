# frozen_string_literal: true

require "rails_helper"

RSpec.describe SplitAccounts::SplitOrderDetailDecorator, type: :decorator do
  let(:order_detail) { build(:order_detail, quantity: 3) }
  let(:split_order_detail) { described_class.new(order_detail) }

  describe "#quantity" do
    context "when quantity_override isn't set" do
      it "returns original quantity" do
        expect(split_order_detail.quantity).to eq(order_detail.quantity)
      end
    end

    context "when quantity_override is set" do
      let(:new_quantity) { 1.5 }
      before(:each) { split_order_detail.quantity = new_quantity }

      it "returns quantity_override" do
        expect(split_order_detail.quantity).to eq(new_quantity)
      end
    end
  end
end
