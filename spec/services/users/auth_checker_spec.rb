require "rails_helper"

RSpec.describe Users::AuthChecker do

  describe "#authenticated?" do
    context "with an external user" do
      let(:user) { create(:user, email: "external@example.org", username: "external@example.org", password: "something") }

      context "with the correct password" do
        let(:auth_user) { described_class.new(user, "something") }

        it "returns true" do
          expect(auth_user.authenticated?).to eq true
        end
      end

      context "with the wrong password" do
        let(:auth_user) { described_class.new(user, "wrong") }

        it "returns false" do
          expect(auth_user.authenticated?).to eq false
        end
      end
    end

    context "with a netid user" do
      let(:user) { create(:user, :netid, email: "internal@example.org", username: "netid") }

      before(:each) do
        allow(LdapAuthentication).to receive(:configured?).and_return(true)
        User.define_method(:valid_ldap_authentication?) { |password| password == "netidpassword" }
      end

      after(:all) do
        User.remove_method(:valid_ldap_authentication?)
      end

      context "with the correct password" do
        let(:auth_user) { described_class.new(user, "netidpassword") }

        it "returns true" do
          expect(auth_user.authenticated?).to eq true
        end
      end

      context "with the wrong password" do
        let(:auth_user) { described_class.new(user, "wrong") }

        it "returns false" do
          expect(auth_user.authenticated?).to eq false
        end
      end
    end

  end

end
