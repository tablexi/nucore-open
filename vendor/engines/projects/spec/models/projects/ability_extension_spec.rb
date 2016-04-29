require "rails_helper"

RSpec.describe Projects::AbilityExtension do
  subject(:ability) { Ability.new(user, facility, stub_controller) }
  let(:facility) { project.facility }
  let(:project) { build(:project) }
  let(:stub_controller) { OpenStruct.new }

  before(:all) { Projects::Engine.enable! }

  shared_examples_for "it has full access" do
    it "has full access" do
      is_expected.to be_allowed_to(:create, Projects::Project)
      is_expected.to be_allowed_to(:index, Projects::Project)
      is_expected.to be_allowed_to(:new, Projects::Project)
    end
  end

  shared_examples_for "it has no access" do
    it "has no access" do
      is_expected.not_to be_allowed_to(:create, Projects::Project)
      is_expected.not_to be_allowed_to(:index, Projects::Project)
      is_expected.not_to be_allowed_to(:new, Projects::Project)
    end
  end

  describe "account manager" do
    let(:user) { create(:user, :account_manager) }
    it_behaves_like "it has no access"
  end

  describe "administrator" do
    let(:user) { create(:user, :administrator) }
    it_behaves_like "it has full access"
  end

  describe "billing administrator", feature_setting: { billing_administrator: true } do
    let(:user) { create(:user, :billing_administrator) }
    it_behaves_like "it has no access"
  end

  describe "facility administrator" do
    let(:user) { create(:user, :facility_administrator, facility: project.facility) }
    it_behaves_like "it has full access"
  end

  describe "facility director" do
    let(:user) { create(:user, :facility_director, facility: project.facility) }
    it_behaves_like "it has full access"
  end

  describe "senior staff" do
    let(:user) { create(:user, :senior_staff, facility: project.facility) }
    it_behaves_like "it has full access"
  end

  describe "staff" do
    let(:user) { create(:user, :staff, facility: project.facility) }
    it_behaves_like "it has full access"
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }
    it_behaves_like "it has no access"
  end
end
