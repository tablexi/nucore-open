# frozen_string_literal: true

require "rails_helper"
require "affiliate_account_helper"

RSpec.describe CreditCardAccount do
  include AffiliateAccountHelper

  before(:each) do
    @user = FactoryBot.create(:user)

    @owner = {
      user: @user,
      created_by: @user.id,
      user_role: "Owner",
    }

    @account_attrs = {
      expiration_month: 1,
      expiration_year: (Time.zone.now + 1.year).year,
      expires_at: Time.zone.now + 1.year,
      description: "account description",
      name_on_card: "Person",
      created_by: @user.id,
      account_users_attributes: [@owner],
    }
  end

  it "should handle facilities" do
    account1 = CreditCardAccount.create(@account_attrs)
    expect(account1).to respond_to(:facility)
  end

  it "should take a facility" do
    facility = FactoryBot.create(:facility)
    @account_attrs[:facility] = facility
    account = CreditCardAccount.create(@account_attrs)
    expect(account.facility).to eq(facility)
  end

  it "should be limited to a single facility" do
    expect(CreditCardAccount.single_facility?).to eq(true)
  end
end
