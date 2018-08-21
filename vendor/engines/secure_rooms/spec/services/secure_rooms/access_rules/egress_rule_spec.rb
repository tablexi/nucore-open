# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessRules::EgressRule, type: :service do
  let(:rule) do
    described_class.new(
      card_user,
      card_reader,
    )
  end
  let(:card_user) { build :user }

  subject(:response) { rule.call }

  context "egress card reader allows exit from the room" do
    let(:card_reader) { build :card_reader, ingress: false }

    it { is_expected.to have_result_code(:grant) }
  end

  context "ingress card reader entrance passes to next rule" do
    let(:card_reader) { build :card_reader, ingress: true }

    it { is_expected.to have_result_code(:pass) }
  end
end
