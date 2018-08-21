# frozen_string_literal: true

require "rails_helper"
require "affiliate_account_helper"

RSpec.describe PurchaseOrderAccount do
  include AffiliateAccountHelper

  subject(:account) { PurchaseOrderAccount.create(@account_attrs) }
  let(:facility) { create(:facility) }
  let(:owner) { { user: user, created_by: user.id, user_role: "Owner" } }
  let(:user) { create(:user) }

  before :each do
    @account_attrs = {
      account_number: "4111-1111-1111-1111",
      description: "account description",
      expires_at: 1.year.from_now,
      created_by: user.id,
      account_users_attributes: [owner],
    }
  end

  it_should_behave_like "an Account"

  it "handles facilities" do
    expect(account).to respond_to :facility
  end

  it "is limited to a single facility" do
    expect(PurchaseOrderAccount).to be_single_facility
  end

  context "with facility" do
    before { @account_attrs[:facility] = facility }

    it "includes the facility in the description" do
      expect(account.to_s).to include account.facility.name
    end

    it "takes a facility" do
      expect(account.facility).to eq facility
    end
  end
end
