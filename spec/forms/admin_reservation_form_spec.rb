require "rails_helper"

RSpec.describe AdminReservationForm do
  include DateHelper

  let(:instrument) { build(:setup_instrument) }
  let(:start_date) { Time.zone.parse("2017-10-17 12:00:00") }
  let(:admin_reservation) { build(:admin_reservation, product: instrument, reserve_start_at: start_date, duration: 1.hour) }
  let!(:form) { AdminReservationForm.new(admin_reservation) }

  describe "validations" do
    it "repeat end date cannot exceed max end date" do
    end

    it "repeat end date must be after initial date" do
    end
  end

  describe "build_recurring_reservations" do

    context "weekdays_only" do
      before do
        form.assign_attributes(repeats: "1", repeat_frequency: "weekdays_only", repeat_end_date: format_usa_date(start_date + 7.days))
      end

      it "builds the right number of reservations" do
        expect(form.build_recurring_reservations.length).to eq 6
      end

      it "sets the group id", :aggregate_failures do
        group_ids = form.build_recurring_reservations.map(&:group_id)
        expect(group_ids.uniq.length).to eq 1
        expect(group_ids).to all(be_present)
      end
    end

    context "daily" do
      context "over daylight savings shift" do
        before do
          form.assign_attributes(repeats: "1", repeat_frequency: "daily", repeat_end_date: format_usa_date(start_date + 30.days))
        end

        it "builds the right number of reservations" do
          expect(form.build_recurring_reservations.length).to eq 31
        end

        it "does not change times" do
          start_times = form.build_recurring_reservations.map { |t| t.reserve_start_at.strftime("%H:%M") }
          expect(start_times).to all(eq "12:00")
        end
      end
    end

    context "weekly" do
    end

    context "monthly" do
    end
  end
end
