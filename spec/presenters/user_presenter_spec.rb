require "rails_helper"

RSpec.describe UserPresenter, feature_setting: { billing_administrator: true } do
  subject { described_class.new(user) }
  let(:global_role_list) { subject.global_role_list }
  let(:global_role_select_options) { subject.global_role_select_options }

  context "when the user has no global roles" do
    let(:user) { create(:user) }

    it { expect(global_role_list).to eq("") }
    it { expect(global_role_select_options).not_to include('selected="selected"') }
  end

  context "when the user has one global role" do
    let(:user) { create(:user, :administrator) }

    it { expect(global_role_list).to eq("Administrator") }
    it { expect(global_role_select_options).to include('selected="selected">Administrator') }
    it { expect(global_role_select_options).not_to include('selected="selected">Billing Administrator') }
  end

  context "when the user has multiple global roles" do
    let(:user) { create(:user, :administrator, :billing_administrator) }

    it { expect(global_role_list).to eq("Administrator, Billing Administrator") }
    it { expect(global_role_select_options).to include('selected="selected">Administrator') }
    it { expect(global_role_select_options).to include('selected="selected">Billing Administrator') }
  end
end
