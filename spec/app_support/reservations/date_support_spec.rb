require "spec_helper"

describe Reservations::DateSupport do
  subject(:reservation) do
    build_stubbed(
      :reservation,
      reserve_start_at: reserve_start_at,
      reserve_end_at: reserve_end_at,
      actual_start_at: actual_start_at,
      actual_end_at: actual_end_at,
    )
  end

  let(:reserve_start_at) { nil }
  let(:reserve_end_at) { nil }
  let(:actual_start_at) { nil }
  let(:actual_end_at) { nil }

  describe "#actual_duration_mins" do
    context "when @actual_duration_mins is set" do
      before { reservation.actual_duration_mins = minutes }

      context "to an integer" do
        let(:minutes) { 1 }

        it "returns @actual_duration_mins as-is" do
          expect(reservation.actual_duration_mins).to eq(1)
        end
      end

      context "to a float" do
        context "where the difference is < 0.5" do
          let(:minutes) { 0.25 }

          it "has no minimum and rounds down to 0" do
            expect(reservation.actual_duration_mins).to eq(0)
          end
        end

        context "where the fraction is < 0.5" do
          let(:minutes) { 1.25 }

          it "rounds down to the minute" do
            expect(reservation.actual_duration_mins).to eq(1)
          end
        end

        context "where the fraction is 0.5" do
          let(:minutes) { 1.5 }

          it "rounds down to the minute" do
            expect(reservation.actual_duration_mins).to eq(1)
          end
        end

        context "where the fraction is > 0.5" do
          let(:minutes) { 1.75 }

          it "rounds down to the minute" do
            expect(reservation.actual_duration_mins).to eq(1)
          end
        end
      end
    end

    context "when actual_start_at is set" do
      let(:actual_start_at) { 1.day.ago }

      context "and the actual duration is < 30 seconds" do
        let(:actual_end_at) { actual_start_at + 29.seconds }

        it "has a 1 minute minimum" do
          expect(reservation.actual_duration_mins).to eq(1)
        end
      end

      context "and the difference to actual_end_at's seconds is < 30" do
        let(:actual_end_at) { actual_start_at + 1.minute + 29.seconds }

        it "rounds down to the minute" do
          expect(reservation.actual_duration_mins).to eq(1)
        end
      end

      context "and the difference to actual_end_at's seconds is 30" do
        let(:actual_end_at) { actual_start_at + 1.minute + 30.seconds }

        it "rounds down to the minute" do
          expect(reservation.actual_duration_mins).to eq(1)
        end
      end

      context "and the difference to actual_end_at's seconds is > 30" do
        let(:actual_end_at) { actual_start_at + 1.minute + 31.seconds }

        it "rounds down to the minute" do
          expect(reservation.actual_duration_mins).to eq(1)
        end
      end

      context "but actual_end_at is unset" do
        context "and the difference to the base time's seconds is < 30" do
          let(:base_time) { actual_start_at + 1.minute + 29.seconds }

          it "rounds down to the minute" do
            expect(reservation.actual_duration_mins(base_time)).to eq(1)
          end
        end

        context "and the difference to the base time's seconds is 30" do
          let(:base_time) { actual_start_at + 1.minute + 30.seconds }

          it "rounds down to the minute" do
            expect(reservation.actual_duration_mins(base_time)).to eq(1)
          end
        end

        context "and the difference to the base time's seconds is > 30" do
          let(:base_time) { actual_start_at + 1.minute + 31.seconds }

          it "rounds down to the minute" do
            expect(reservation.actual_duration_mins(base_time)).to eq(1)
          end
        end
      end
    end

    context "when both actuals are unset" do
      it "is 0" do
        expect(reservation.actual_duration_mins).to eq(0)
      end
    end
  end

  describe "#duration_mins" do
    context "when @duration_mins is set" do
      before { reservation.duration_mins = minutes }

      context "to an integer" do
        let(:minutes) { 1 }

        it "returns @duration_mins as-is" do
          expect(reservation.duration_mins).to eq(1)
        end
      end

      context "to a float" do
        context "where the fraction is < 0.5" do
          let(:minutes) { 1.25 }

          it "rounds down to the minute" do
            expect(reservation.duration_mins).to eq(1)
          end
        end

        context "where the fraction is 0.5" do
          let(:minutes) { 1.5 }

          it "rounds down to the minute" do
            expect(reservation.duration_mins).to eq(1)
          end
        end

        context "where the fraction is > 0.5" do
          let(:minutes) { 1.75 }

          it "rounds down to the minute" do
            expect(reservation.duration_mins).to eq(1)
          end
        end
      end
    end

    context "when @duration_mins is unset" do
      context "when reserve_start_at is set" do
        let(:reserve_start_at) { 1.day.ago }

        context "and the reservation duration is < 30 seconds" do
          let(:reserve_end_at) { reserve_start_at + 29.seconds }

          it "has no minimum and rounds down to 0" do
            expect(reservation.duration_mins).to eq(0)
          end
        end

        context "and the difference to reserve_end_at's seconds is < 30" do
          let(:reserve_end_at) { reserve_start_at + 1.minute + 29.seconds }

          it "rounds down to the minute" do
            expect(reservation.duration_mins).to eq(1)
          end
        end

        context "and the difference to reserve_end_at's seconds is 30" do
          let(:reserve_end_at) { reserve_start_at + 1.minute + 30.seconds }

          it "rounds down to the minute" do
            expect(reservation.duration_mins).to eq(1)
          end
        end

        context "and the difference to reserve_end_at's seconds is > 30" do
          let(:reserve_end_at) { reserve_start_at + 1.minute + 31.seconds }

          it "rounds down to the minute" do
            expect(reservation.duration_mins).to eq(1)
          end
        end

        context "and reserve_end_at is unset" do
          it "is 0" do
            expect(reservation.duration_mins).to eq(0)
          end
        end
      end

      context "when reserve_start_at is unset" do
        it "is 0" do
          expect(reservation.duration_mins).to eq(0)
        end
      end
    end
  end
end
