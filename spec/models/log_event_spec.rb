# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogEvent do

  describe "polymorphic joins" do
    let(:account) { create(:account, :with_account_owner, account_number: "123456") }
    let(:log_event) { create(:log_event, loggable: account) }

    it "can join polymorphicly to an account" do
      relation = described_class.joins_polymorphic(Account).where(accounts: { account_number: "123456" })
      expect(relation).to include(log_event)
    end
  end

end
