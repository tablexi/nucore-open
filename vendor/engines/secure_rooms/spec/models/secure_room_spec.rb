require "rails_helper"

RSpec.describe SecureRoom do
  describe "default values" do
    subject(:room) { described_class.new }
    before { room.validate }

    it { is_expected.to be_requires_approval }
    it { is_expected.to be_hidden }

    describe "and you try to override them" do
      before do
        room.requires_approval = false
        room.hidden = false
        room.validate
      end

      it { is_expected.to be_requires_approval }
      it { is_expected.to be_hidden }
    end
  end
end
