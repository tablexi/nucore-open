# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::CardNumberAbility do
  subject(:ability) { described_class.new(current_user, facility) }
  let(:card_user) { FactoryBot.build(:user) }
  let(:facility) { FactoryBot.create(:facility) }

  describe "administrator" do
    let(:current_user) { FactoryBot.create(:user, :administrator) }
    it { is_expected.to be_allowed_to(:edit, card_user) }
  end

  describe "facility administrator" do
    let(:current_user) { FactoryBot.create(:user, :facility_administrator, facility: facility) }
    it { is_expected.to be_allowed_to(:edit, card_user) }
  end

  describe "facility director" do
    let(:current_user) { FactoryBot.create(:user, :facility_director, facility: facility) }
    it { is_expected.to be_allowed_to(:edit, card_user) }
  end

  describe "senior staff" do
    let(:current_user) { FactoryBot.create(:user, :senior_staff, facility: facility) }
    it { is_expected.to be_allowed_to(:edit, card_user) }
  end

  describe "staff" do
    let(:current_user) { FactoryBot.create(:user, :staff, facility: facility) }
    it { is_expected.to be_allowed_to(:edit, card_user) }
  end

  describe "unprivileged user" do
    let(:current_user) { FactoryBot.create(:user) }
    it { is_expected.not_to be_allowed_to(:edit, card_user) }
  end
end
