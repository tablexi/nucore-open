require "rails_helper"

RSpec.describe FacilitiesHelper do
  describe "#facility_default_admin_path" do
    let(:facility) { create(:setup_facility) }
    let(:result) { facility_default_admin_path(facility) }

    context "when the facility has no active instruments" do
      it { expect(result).to eq(facility_orders_path(facility)) }
    end

    context "when the facility has active instruments" do
      before { create(:setup_instrument, facility: facility) }

      it { expect(result).to eq(timeline_facility_reservations_path(facility)) }
    end

    context "when a non-facility is passed in as a facility argument" do
      let(:facility) { nil }

      it { expect { result }.to raise_error(NoMethodError) }
    end
  end

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
