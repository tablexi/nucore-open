# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::AbilityExtension do
  subject(:ability) { Ability.new(user, facility, stub_controller) }
  let(:common_actions) { %i(create edit inactive index new show update) }
  let(:facility) { project.facility }
  let(:project) { FactoryBot.build(:project) }
  let(:stub_controller) { OpenStruct.new }

  shared_examples_for "it has full access" do
    it "has full access" do
      common_actions.each do |action|
        is_expected.to be_allowed_to(action, Projects::Project)
      end
    end
  end

  shared_examples_for "it has no access" do
    it "has no access" do
      common_actions.each do |action|
        is_expected.not_to be_allowed_to(action, Projects::Project)
      end
    end
  end

  describe "account manager" do
    let(:user) { FactoryBot.create(:user, :account_manager) }
    it_behaves_like "it has no access"
  end

  describe "administrator" do
    let(:user) { FactoryBot.create(:user, :administrator) }
    it_behaves_like "it has full access"
  end

  describe "billing administrator", feature_setting: { billing_administrator: true } do
    let(:user) { FactoryBot.create(:user, :billing_administrator) }
    it_behaves_like "it has no access"
  end

  describe "facility administrator" do
    let(:user) { FactoryBot.create(:user, :facility_administrator, facility: facility) }
    it_behaves_like "it has full access"
  end

  describe "facility director" do
    let(:user) { FactoryBot.create(:user, :facility_director, facility: facility) }
    it_behaves_like "it has full access"
  end

  describe "senior staff" do
    let(:user) { FactoryBot.create(:user, :senior_staff, facility: facility) }
    it_behaves_like "it has full access"
  end

  describe "staff" do
    let(:user) { FactoryBot.create(:user, :staff, facility: facility) }
    it_behaves_like "it has full access"
  end

  describe "unprivileged user" do
    let(:user) { FactoryBot.create(:user) }
    it_behaves_like "it has no access"
  end
end
