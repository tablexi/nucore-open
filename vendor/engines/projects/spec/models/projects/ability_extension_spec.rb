require "rails_helper"

RSpec.describe Projects::AbilityExtension do
  subject(:ability) { Ability.new(user, facility, stub_controller) }
  let(:facility) { project.facility }
  let(:project) { build(:project) }
  let(:stub_controller) { OpenStruct.new }

  before(:all) { Projects::Engine.enable! }

  describe "account manager" do
    let(:user) { create(:user, :account_manager) }
    it { is_expected.not_to be_allowed_to(:index, Projects::Project) }
  end

  describe "administrator" do
    let(:user) { create(:user, :administrator) }
    it { is_expected.to be_allowed_to(:index, Projects::Project) }
  end

  describe "billing administrator", feature_setting: { billing_administrator: true } do
    let(:user) { create(:user, :billing_administrator) }
    it { is_expected.not_to be_allowed_to(:index, Projects::Project) }
  end

  describe "facility administrator" do
    let(:user) { create(:user, :facility_administrator, facility: project.facility) }
    it { is_expected.to be_allowed_to(:index, Projects::Project) }
  end

  describe "facility director" do
    let(:user) { create(:user, :facility_director, facility: project.facility) }
    it { is_expected.to be_allowed_to(:index, Projects::Project) }
  end

  describe "senior staff" do
    let(:user) { create(:user, :senior_staff, facility: project.facility) }
    it { is_expected.to be_allowed_to(:index, Projects::Project) }
  end

  describe "staff" do
    let(:user) { create(:user, :staff, facility: project.facility) }
    it { is_expected.to be_allowed_to(:index, Projects::Project) }
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }
    it { is_expected.not_to be_allowed_to(:index, Projects::Project) }
  end
end
