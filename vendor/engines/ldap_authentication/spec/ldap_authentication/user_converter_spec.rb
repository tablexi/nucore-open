# frozen_string_literal: true

require "rails_helper"

RSpec.describe LdapAuthentication::UserConverter do
  let(:net_ldap_entry) do
    double(
      "Fake::Net::LDAP::Entry",
      givenname: ["First"],
      sn: ["Last"],
      uid: ["uname"],
      mail: ["primary@example.org", "secondary@example.org"],
    )
  end

  let(:user_entry) { LdapAuthentication::UserEntry.new(net_ldap_entry) }
  let(:converter) { described_class.new(user_entry) }

  describe "to_user" do
    let(:user) { converter.to_user }

    it "is a ::User" do
      expect(user).to be_an_instance_of(::User)
    end

    it "is not persisted" do
      expect(user).to be_new_record
    end

    it "has the email set" do
      expect(user.email).to eq("primary@example.org")
    end

    it "has the first name set" do
      expect(user.first_name).to eq("First")
    end

    it "has the last name set" do
      expect(user.last_name).to eq("Last")
    end

    it "has the username set" do
      expect(user.username).to eq("uname")
    end
  end

  describe "attributes" do
    it "fills out the attribute hash" do
      expect(converter.attributes).to match_array(
        username: "uname",
        first_name: "First",
        last_name: "Last",
        email: "primary@example.org",
      )
    end
  end
end
