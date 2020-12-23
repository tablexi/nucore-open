
require "rails_helper"

RSpec.describe NucoreKfs::ChartOfAccounts do

  # We want this to serve as an integration test with UConn's KFS system, so we prefer not to mock these requests.
  WebMock.disable_net_connect!(allow: 'kualinp.uconn.edu')

  it "can load the list of accounts for a single subfund" do
    api = NucoreKfs::ChartOfAccounts.new
    result = api.do_call_for_subfund('OPAUX')
  end

  it "gets the expected fields for accounts" do
    api = NucoreKfs::ChartOfAccounts.new
    result = api.do_call_for_subfund('OPAUX')

    accounts = result.body[:get_accounts_response][:return][:account]
    account = accounts[0]

    expect(account).to have_key(:account_name)
    expect(account).to have_key(:status)
  end

  it "can upsert a single subfund" do
    api = NucoreKfs::ChartOfAccounts.new
    result = api.upsert_accounts_for_subfund('OPAUX')
  end

end
