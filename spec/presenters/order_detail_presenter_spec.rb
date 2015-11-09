require "rails_helper"

RSpec.describe OrderDetailPresenter do
  let(:presented) { OrderDetailPresenter.new(order_detail) }
  let(:order_detail) { build_stubbed(:order_detail) }

  RSpec.shared_context "order with a reservation" do
    let(:facility) { order_detail.facility }
    let(:order) { order_detail.order }
    let(:order_detail) { reservation.order_detail }
    let(:reservation) { create(:setup_reservation) }
  end

  describe "#actual_total" do
    subject { presented.actual_total }

    before { allow(order_detail).to receive(:actual_total) { actual_total } }

    context "when there is an actual_total value" do
      let(:actual_total) { 20.15 }

      it { is_expected.to eq("$20.15") }
    end

    context "when there is no actual_total value" do
      let(:actual_total) { nil }

      it { is_expected.to eq("") }
    end
  end

  describe "#description_as_html" do
    subject { presented.description_as_html }

    let(:product) { build_stubbed(:product, name: "<Micro> & >Scope<") }

    before(:each) do
      allow(order_detail).to receive(:bundle) { bundle }
      allow(order_detail).to receive(:product) { product }
    end

    context "when part of a bundle" do
      let(:bundle) { build_stubbed(:bundle, name: ">Bun & dle<") }

      it { is_expected.to eq("&gt;Bun &amp; dle&lt; &mdash; &lt;Micro&gt; &amp; &gt;Scope&lt;") }
      it { is_expected.to be_html_safe }
    end

    context "when not part of a bundle" do
      let(:bundle) { nil }

      it { is_expected.to eq("&lt;Micro&gt; &amp; &gt;Scope&lt;") }
      it { is_expected.to be_html_safe }
    end
  end

  describe "#edit_reservation_path" do
    subject { presented.edit_reservation_path }

    include_context "order with a reservation"

    let(:expected_path) do
      "/facilities/#{facility.url_name}/orders/#{order.id}/order_details/"\
      "#{order_detail.id}/reservations/#{reservation.id}/edit"
    end

    it { is_expected.to eq(expected_path) }
  end

  describe "#estimated_total" do
    subject { presented.estimated_total }

    before(:each) do
      allow(order_detail).to receive(:estimated_total) { estimated_total }
    end

    context "when there is an estimated_total value" do
      let(:estimated_total) { 20.15 }

      it { is_expected.to eq("$20.15") }
    end

    context "when there is no estimated_total value" do
      let(:estimated_total) { nil }

      it { is_expected.to eq("") }
    end
  end

  describe "#ordered_at" do
    subject { presented.ordered_at }
    let(:order) { build_stubbed(:order, ordered_at: ordered_at) }
    let(:ordered_at) { Time.zone.parse("2015-02-01T13:00:59") }

    before { allow(order_detail).to receive(:order) { order } }

    it { is_expected.to eq("02/01/2015  1:00 PM") }
  end

  describe "#row_class" do
    subject { presented.row_class }

    before { allow(order_detail).to receive(:reconciled?) { reconciled? } }

    context "when reconciled" do
      let(:reconciled?) { true }

      it { is_expected.to eq("") }
    end

    context "when not reconciled" do
      let(:reconciled?) { false }

      before { allow(order_detail).to receive(:fulfilled_at) { fulfilled_at } }

      context "and not fulfilled" do
        let(:fulfilled_at) { nil }

        it { is_expected.to eq("") }
      end

      context "and fulfilled" do
        context "fewer than 60 days ago" do
          let(:fulfilled_at) { 59.days.ago }

          it { is_expected.to eq("") }
        end

        context "more than 60 days ago" do
          let(:fulfilled_at) { 61.days.ago }

          it { is_expected.to eq("reconcile-warning") }
        end
      end
    end
  end

  describe "#show_order_path" do
    subject { presented.show_order_path }

    include_context "order with a reservation"

    it { is_expected.to eq("/facilities/#{facility.url_name}/orders/#{order.id}") }
  end

  describe "#show_reservation_path" do
    subject { presented.show_reservation_path }

    include_context "order with a reservation"

    let(:expected_path) do
      "/facilities/#{facility.url_name}/orders/#{order.id}/order_details/"\
      "#{order_detail.id}/reservations/#{reservation.id}"
    end

    it { is_expected.to eq(expected_path) }
  end

  describe "#survey_url" do
    subject { presented.survey_url }

    before(:each) do
      allow(order_detail).to receive(:external_service_receiver) do
        external_service_receiver
      end
    end

    context "when a survey has been completed" do
      let(:external_service_receiver) { OpenStruct.new(show_url: show_url) }
      let(:show_url) { "https://example.org/survey.html" }

      it { is_expected.to eq("https://example.org/survey.html") }
    end

    context "when a survey has not been completed" do
      let(:external_service_receiver) { nil }

      it { is_expected.to eq("") }
    end
  end
end
