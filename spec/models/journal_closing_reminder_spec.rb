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

  describe "ends_at=" do
    context "with a valid string" do
      let(:ends_at) { "02/01/2022" }

      it "set the ends_at to the end of the day" do
        expect(reminder.ends_at).to eq(Time.zone.parse("2022-02-01 23:59:59"))
      end
    end

    context "with an invalid string" do
      let(:ends_at) { "02/01/222" }

      it "doesn't error" do
        expect(reminder.ends_at).to eq nil
      end
    end

    context "with nil" do
      let(:ends_at) { nil }

      it "doesn't error" do
        expect(reminder.ends_at).to eq nil
      end
    end
  end

  describe "starts_at=" do
    context "with a valid string" do
      let(:starts_at) { "02/01/2022" }

      it "set the value to the start of the day" do
        expect(reminder.starts_at).to eq(Time.zone.parse("2022-02-01 00:00:00"))
      end
    end

    context "with an invalid string" do
      let(:starts_at) { "02/01/222" }

      it "doesn't error" do
        expect(reminder.starts_at).to eq nil
      end
    end

    context "with nil" do
      let(:starts_at) { nil }

      it "doesn't error" do
        expect(reminder.starts_at).to eq nil
      end
    end
  end
end
