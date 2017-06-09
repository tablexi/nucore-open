require "rails_helper"

RSpec.describe User do
  let(:user_entry) do
    double("UserEntry", username: "abc123", first_name: "First", last_name: "Last", email: "primary@example.org")
  end

  before do
    allow(LdapAuthentication::UserEntry).to receive(:find).with("abc123").and_return(user_entry)
    allow(LdapAuthentication::UserEntry).to receive(:find).with("xyz789").and_return(nil)
  end

  it "updates the attributes after successful ldap authentication" do
    user = create(:user, username: "abc123")
    user.after_ldap_authentication
    user.reload

    expect(user.first_name).to eq("First")
    expect(user.last_name).to eq("Last")
    expect(user.email).to eq("primary@example.org")
  end

  it "raises an error if the user is not found" do
    user = create(:user, username: "xyz789")
    expect { user.after_ldap_authentication }.to raise_error(/not found in LDAP/)
  end

  describe "a validation error" do
    let!(:old_user) { create(:user, email: "primary@example.org") }
    let!(:user) { create(:user, email: "old@example.org", username: "abc123") }

    it "triggers a notification" do
      expect(ActiveSupport::Notifications).to receive(:instrument).with("background_error", a_hash_including(information: /Could not update User/))

      user.after_ldap_authentication
    end

    it "does not update the user's information" do
      user.after_ldap_authentication
      user.reload
      expect(user.email).to eq("old@example.org")
    end
  end
end
