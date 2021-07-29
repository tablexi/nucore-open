# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalClosingReminder do
  subject(:reminder) { described_class.create(starts_at: starts_at, ends_at: ends_at, message: "Don't forget to submit your journal before year end!") }
  let(:starts_at) { nil }
  let(:ends_at) { nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }
    it { is_expected.to validate_presence_of(:message) }

    describe "starts_before_ends" do
      context "when starts_at is before ends_at" do
        let(:starts_at) { 3.days.ago }
        let(:ends_at) { 3.days.from_now }

        it { is_expected.to be_valid }
      end

      context "when starts_at is after ends_at" do
        let(:starts_at) { 3.days.from_now }
        let(:ends_at) { 3.days.ago }

        it { is_expected.to be_invalid }

        it "has an error message" do
          expect(reminder.errors.messages).to eq({ starts_at: ["must be after Ending Date"] })
        end
      end

      context "when starts_at is the same as ends_at" do
        let(:current_time) { Time.current }
        let(:starts_at) { current_time }
        let(:ends_at) { current_time }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "update_ends_at_to_end_of_day" do
    context "when ends_at is present" do
      let(:starts_at) { nil }
      let(:ends_at) { Time.current }

      it "sets ends_at to end of day" do
        expect(reminder.ends_at).to be_within(1.second).of(ends_at.end_of_day)
      end
    end

    context "when ends_at is nil" do
      let(:starts_at) { 3.days.ago }
      let(:ends_at) { nil }

      it "doesn't error" do
        expect(reminder.ends_at).to eq nil
      end
    end
  end

  describe "ends_at_date_time_data" do
    let(:ends_at) { Time.zone.parse("2022-01-01") }

    it "generates a hash of date time data" do
      expect(reminder.ends_at_date_time_data.to_h).to eq({ date: "01/01/2022", hour: 11, minute: 59, ampm: "PM" })
    end
  end

  describe "ends_at=" do
    let(:ends_at) { { date: "02/01/2022", hour: 12, minute: 0, ampm: "AM" } }

    it "set the ends_at from a hash of date time data" do
      expect(reminder.ends_at).to eq(Time.zone.parse("2022-02-01 23:59:59"))
    end
  end

  describe "starts_at_date_time_data" do
    let(:starts_at) { Time.zone.parse("2022-01-01") }

    it "generates a hash of date time data" do
      expect(reminder.starts_at_date_time_data.to_h).to eq({ date: "01/01/2022", hour: 12, minute: 00, ampm: "AM" })
    end
  end

  describe "starts_at=" do
    let(:starts_at) { { date: "02/01/2022", hour: 12, minute: 0, ampm: "AM" } }

    it "sets the starts_at from a hash of date time data" do
      expect(reminder.starts_at).to eq(Time.zone.parse("2022-02-01 00:00:00"))
    end
  end
end
