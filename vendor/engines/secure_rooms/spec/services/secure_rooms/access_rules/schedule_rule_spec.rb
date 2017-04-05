require "rails_helper"

RSpec.describe SecureRooms::AccessRules::ScheduleRule do
  let(:user) { build(:user) }
  let(:secure_room) { create(:secure_room) }
  let(:card_reader) { build(:card_reader, secure_room: secure_room) }

  subject(:result) do
    described_class.new(
      user,
      card_reader,
    ).call
  end

  describe "there are no schedule rules" do
    it { is_expected.to be_denied }
  end

  describe "there is a schedule rule", :timecop_freeze do
    # Factory default to 9-5 every day
    let!(:schedule_rule) { secure_room.schedule_rules.create(attributes_for(:schedule_rule)) }

    describe "and it is inside the rule" do
      let(:now) { Time.new(2017, 4, 5, 12, 00) }

      it { is_expected.to be_pass }
    end

    describe "and it is outside the rule" do
      let(:now) { Time.new(2017, 4, 5, 19, 00) }
    end
  end
end
