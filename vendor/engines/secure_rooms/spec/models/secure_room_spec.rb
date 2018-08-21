# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRoom do
  subject(:room) { described_class.new }
  before { room.validate }

  describe "default values" do
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

  describe "dasboard_token generation" do
    subject { room.dashboard_token }
    it { is_expected.to be_present }
  end
end
