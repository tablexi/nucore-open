# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilitiesHelper do
  describe "#product_list_title" do
    let(:products) { %i(instrument item service).map { |type| build(type) } }
    let(:result) { product_list_title(products, extra) }

    context "when extra is falsy" do
      let(:extra) { nil }

      it { expect(result).to be_html_safe }
      it { expect(result).to eq("Instruments") }
    end

    context "when extra is truthy" do
      let(:extra) { '<Extra> & "text"' }

      it { expect(result).to be_html_safe }
      it { expect(result).to eq('Instruments (<Extra> & "text")') }
    end
  end
end
