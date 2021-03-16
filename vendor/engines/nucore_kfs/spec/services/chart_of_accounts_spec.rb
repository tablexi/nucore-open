require "rails_helper"

RSpec.describe NucoreKfs::ChartOfAccounts, type: :service do
  let(:api) { described_class.new }
  let(:owner) { FactoryBot.create(:user) }
  let(:business_admin) { FactoryBot.create(:user) }
  let(:kfs_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: owner, account_number: "KFS-7777777-6610") }
  let(:kfs_soap_data) { Hash({:account_number => "7777777",
                          :account_name => "test account",
                          :status => "OPEN",
                          :fiscal_officer_identifier => business_admin.username,
                          :accounts_supervisory_systems_identifier => owner.username
                          })
                        }

  # We want this to serve as an integration test with UConn's KFS system, so we prefer not to mock these requests.
  WebMock.disable_net_connect!(allow: 'kualinp.uconn.edu')

  it "can load the list of accounts for a single subfund", :if => ENV['VPN_ENABLED'] do
    result = api.do_call_for_subfund('OPAUX')

    accounts = result.body[:get_accounts_response][:return][:account]

    expect(accounts).not_to be_empty
  end

  it "gets the expected fields for accounts", :if => ENV['VPN_ENABLED'] do
    result = api.do_call_for_subfund('OPAUX')

    accounts = result.body[:get_accounts_response][:return][:account]
    account = accounts[0]

    expect(account).to have_key(:account_name)
    expect(account).to have_key(:account_number)
    expect(account).to have_key(:status)
  end

  it "can build account" do
    result = api.build_account(1, owner, kfs_account.description)

    expect(result).to_not be_nil
  end

  it "can build accounts with the correct fields" do
    result = api.build_account(1, owner, kfs_account.description)

    expect(result[:account_number].to_i).to eq(1)
    expect(result.description).to eq(kfs_account.description)
    expect(result.owner_user.id).to eq(owner.id)
    expect(result.owner_user).to eq(owner)
  end

  it "can change user role from owner to business admin" do
    result = api.create_business_admin_record(kfs_account, business_admin)

    expect(kfs_account.account_users.where(user_id: business_admin.id).first.user_role).to eq("Business Administrator")
  end

  it "changes user role from owner to business admin when assigning user to account" do
    result = api.set_business_admin_for_account(kfs_account, business_admin)
    
    expect(kfs_account.account_users.where(user_id: business_admin.id).first.user_role).to eq("Business Administrator")
  end

  it "can update owner of account" do
    result = api.create_account_owner_record(kfs_account, owner)

    expect(kfs_account.account_users.where(user_id: owner.id).first.user_role).to eq("Owner")
  end

  it "can build correct account number" do
    account_number = api.build_account_number(kfs_soap_data)

    expect(account_number).to eq("KFS-7777777-6610")
  end

  it "can find the correct account in upsert" do
    account = kfs_account
    api.upsert_account(kfs_soap_data)

    expect(account.owner_user.username).to eq(owner.username)
  end

  it "can insert account in upsert" do
    api.upsert_account(kfs_soap_data)

    expect(Account.find_by(account_number: "KFS-7777777-6610")).to_not be_nil
  end

  it "can update existing account in upsert" do
    kfs_soap_data[:fiscal_officer_identifier] = owner.username
    kfs_soap_data[:accounts_supervisory_systems_identifier] = business_admin.username

    account = kfs_account
    api.upsert_account(kfs_soap_data)

    expect(account.owner_user.id).to eq(business_admin.id)
    expect(account.owner_user.username).to eq(business_admin.username)
  end

  it "only upserts accounts with valid owner and administrator" do
    kfs_soap_data[:fiscal_officer_identifier] = nil
    kfs_soap_data[:accounts_supervisory_systems_identifier] = nil

    expect(api.upsert_account(kfs_soap_data)).to be_nil
  end

  it "suspends closed account" do
    kfs_account.unsuspend
    kfs_soap_data[:status] = "CLOSED"
    api.upsert_account(kfs_soap_data)
    kfs_account.reload

    expect(kfs_account.suspended?).to be true
  end

  it "unsuspends open account" do
    kfs_account.suspend
    api.upsert_account(kfs_soap_data)
    kfs_account.reload

    expect(kfs_account.suspended?).to be false
  end

  it "can upsert a single subfund", :if => ENV['VPN_ENABLED'] do
    expect{api.upsert_accounts_for_subfund('OPAUX')}.to_not raise_error
  end
end
