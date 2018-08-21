# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailUpdateParamHashExtractor do
  describe "#to_h" do
    subject { described_class.new(params).to_h }

    context "when the params contain a quantity key" do
      let(:params) { ActionController::Parameters.new("quantity101" => quantity_value) }

      context "with a value" do
        let(:quantity_value) { "5" }

        it { is_expected.to eq(101 => { quantity: "5" }) }
      end

      context "with a nil value" do
        let(:quantity_value) { nil }

        it { is_expected.to eq(101 => { quantity: nil }) }
      end
    end

    context "when the params contain a note key" do
      let(:params) { ActionController::Parameters.new("note202" => note_value) }

      context "with a value" do
        let(:note_value) { "This is a note" }

        it { is_expected.to eq(202 => { note: "This is a note" }) }
      end

      context "with a nil value" do
        let(:note_value) { nil }

        it { is_expected.to eq({}) }
      end
    end
  end
end
