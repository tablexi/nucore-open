require "rails_helper"

RSpec.describe Reservations::Rendering do
  subject(:reservation) do
    build_stubbed(
      :reservation,
      reserve_start_at: reserve_start_at,
      reserve_end_at: reserve_end_at,
      actual_start_at: actual_start_at,
      actual_end_at: actual_end_at,
      canceled_at: canceled_at,
    )
  end

  let(:reserve_start_at) { nil }
  let(:reserve_end_at) { nil }
  let(:actual_start_at) { nil }
  let(:actual_end_at) { nil }
  let(:canceled_at) { nil }

  describe "#actuals_string" do
    context "when there is an actual start_at" do
      let(:actual_start_at) { Time.zone.local(2015, 6, 1, 8, 14, 15) }

      context "and an actual end_at" do
        let(:actual_end_at) { Time.zone.local(2015, 6, 1, 9, 15, 16) }

        it "returns the formatted range" do
          expect(reservation.actuals_string)
            .to eq("Mon, 06/01/2015 8:14 AM - 9:15 AM")
        end
      end

      context "and no actual end_at" do
        it "formats the start time and uses '???' for the end time" do
          expect(reservation.actuals_string)
            .to eq("Mon, 06/01/2015 8:14 AM - ???")
        end
      end
    end

    context "when there is no actual start_at" do
      context "and there is an actual end_at" do
        let(:actual_end_at) { Time.zone.local(2015, 6, 1, 9, 15, 16) }

        it "uses '???' for the start time and formats the end time" do
          expect(reservation.actuals_string)
            .to eq("??? - Mon, 06/01/2015 9:15 AM ") # NOTE trailing space
        end
      end

      context "and there is no actual end_at" do
        it "returns a no actual times message" do
          expect(reservation.actuals_string).to eq("No actual times recorded")
        end
      end
    end
  end

  describe "#as_calendar_object" do
    let(:actual_start_at) { Time.zone.local(2015, 8, 1, 9, 15, 16) }
    let(:actual_end_at) { Time.zone.local(2015, 8, 1, 10, 16, 17) }
    let(:title) { "Admin\nReservation" }

    let(:hash_without_details) do
      {
        "allDay" => false,
        "end" => "Sat, 01 Aug 2015 10:16:17",
        "product" => "Generic",
        "start" => "Sat, 01 Aug 2015 09:15:16",
        "title" => title,
      }
    end

    before { reservation.product = build_stubbed(:product, name: "Generic") }

    context "with an order" do
      let(:order) { build_stubbed(:order, user: user) }
      let(:user) { build_stubbed(:user) }

      let(:hash_with_details) do
        hash_without_details.merge(
          "admin" => false,
          "email" => user.email,
          "name" => user.full_name,
        )
      end

      before { allow(reservation).to receive(:order).and_return(order) }

      context "with details requested" do
        let(:title) { "#{user.first_name}\n#{user.last_name}" }

        it "returns a hash with extra details about the order" do
          expect(reservation.as_calendar_object(with_details: true))
            .to eq(hash_with_details)
        end
      end

      context "without details requested" do
        let(:title) { "Reservation" }

        it "returns a hash without extra details about the order" do
          expect(reservation.as_calendar_object).to eq(hash_without_details)
        end
      end
    end

    context "without an order" do
      let(:hash_with_no_order) { hash_without_details.merge("admin" => true) }

      context "with details requested" do
        it "returns a hash without extra details about the order" do
          expect(reservation.as_calendar_object(with_details: true))
            .to eq(hash_with_no_order)
        end
      end

      context "without details requested" do
        it "returns a hash without extra details about the order" do
          expect(reservation.as_calendar_object).to eq(hash_with_no_order)
        end
      end
    end
  end

  describe "#display_start_at" do
    context "when there is an actual start time" do
      let(:actual_start_at) { 4.hours.ago }

      it "returns the actual start time" do
        expect(reservation.display_start_at).to eq(reservation.actual_start_at)
      end
    end

    context "when there is no actual start time" do
      context "and there is a reserve start time" do
        let(:reserve_start_at) { 5.hours.ago }

        it "returns the reserve start time" do
          expect(reservation.display_start_at).to eq(reserve_start_at)
        end
      end

      context "and there is no reserve start time" do
        it "returns blank" do
          expect(reservation.display_start_at).to be_blank
        end
      end
    end
  end

  describe "#display_end_at" do
    context "when there is an actual end time" do
      let(:actual_end_at) { 3.hours.ago }

      it "returns the actual end time" do
        expect(reservation.display_end_at).to eq(actual_end_at)
      end
    end

    context "when there is no actual end time" do
      context "and there is a reserve end time" do
        let(:reserve_end_at) { 2.hours.ago }

        it "returns the reserve end time" do
          expect(reservation.display_end_at).to eq(reserve_end_at)
        end
      end

      context "and there is no reserve end time" do
        it "returns blank" do
          expect(reservation.display_end_at).to be_blank
        end
      end
    end
  end

  describe "#range_to_s" do
    let(:result) { reservation.range_to_s(start_at, end_at) }
    let(:start_at) { Time.zone.local(2015, 6, 1, 13, 14, 15) }

    context "when the reservation is within a single day" do
      let(:end_at) { start_at + 1.hour }

      it "displays the end time without the date" do
        expect(result).to eq("Mon, 06/01/2015 1:14 PM - 2:14 PM")
      end
    end

    context "when the reservation spans more than one day" do
      let(:end_at) { start_at + 30.hours }

      it "displays the end time with the date" do
        expect(result)
          .to eq("Mon, 06/01/2015 1:14 PM - Tue, 06/02/2015 7:14 PM")
      end
    end
  end

  describe "#reserve_to_s" do
    let(:reserve_start_at) { Time.zone.local(2015, 5, 1, 8, 14, 15) }
    let(:reserve_end_at) { Time.zone.local(2015, 5, 1, 9, 15, 16) }

    it "formats the reservation start and end time range" do
      expect(reservation.reserve_to_s)
        .to eq("Fri, 05/01/2015 8:14 AM - 9:15 AM")
    end
  end

  describe "#to_s" do
    context "when there are reserve start and end times" do
      let(:reserve_start_at) { Time.zone.local(2015, 7, 1, 8, 14, 15) }
      let(:reserve_end_at) { Time.zone.local(2015, 7, 1, 9, 15, 16) }

      context "and the reservation is not canceled" do
        it "returns the formatted range" do
          expect(reservation.to_s).to eq("Wed, 07/01/2015 8:14 AM - 9:15 AM")
        end
      end

      context "and the reservation is canceled" do
        let(:canceled_at) { 4.hours.ago }

        it "returns the formatted range with '(Canceled)' appended" do
          expect(reservation.to_s)
            .to eq("Wed, 07/01/2015 8:14 AM - 9:15 AM (Canceled)")
        end
      end
    end
  end
end
