require "rails_helper"

RSpec.describe GlobalUserRolesController do
  shared_examples_for "the user must log in" do
    it "redirects to the login screen" do
      expect(response).to be_redirect
      expect(response.location).to eq(new_user_session_url)
    end
  end

  shared_examples_for "the user is not allowed" do
    it { expect(response).to be_forbidden }
  end

  describe "#index" do
    before(:each) do
      sign_in(user) if user.present?
      get(:index)
    end

    context "when not logged in" do
      let(:user) { nil }

      it_behaves_like "the user must log in"
    end

    context "when logged in" do
      context "as an unprivileged user" do
        let(:user) { create(:user) }

        it_behaves_like "the user is not allowed"
      end

      context "as a global administrator" do
        let(:user) { create(:user, :administrator) }

        it { expect(response).to be_success }
      end
    end
  end

  describe "#destroy" do
    let(:administrators) { create_list(:user, 2, :administrator) }
    let(:user) { administrators.first }

    before(:each) do
      sign_in(user)
      delete(:destroy, id: user_with_roles_to_destroy)
    end

    context "when removing global roles for another user" do
      let(:user_with_roles_to_destroy) { administrators.last }

      it "removes global administrator roles from the user" do
        expect(flash[:notice]).to include("roles have been removed")
        expect(user_with_roles_to_destroy).not_to be_administrator
      end
    end

    context "when attempting to remove global roles from itself" do
      let(:user_with_roles_to_destroy) { user }

      it "removes no global administrator roles" do
        expect(flash[:error]).to include("may not remove global roles")
        expect(administrators).to all be_administrator
      end
    end
  end

  describe "#update" do
    let(:administrator) { create(:user, :administrator) }
    let(:role) { "Administrator" }

    before(:each) do
      sign_in(administrator)
      put(:update, id: user.id, user_role: { role: role })
    end

    after { expect(response).to redirect_to(global_user_roles_url) }

    context "when updating the current user's global roles" do
      let(:user) { administrator }

      it "does not update global roles" do
        expect(flash[:error]).to include("may not change global roles")
        expect(administrator).to be_administrator
      end
    end

    context "when the user has no existing global roles" do
      let(:user) { create(:user) }

      it "grants the role" do
        expect(flash[:notice]).to include("granted to")
        expect(user).to be_administrator
      end
    end

    context "when the user has an existing global role" do
      let(:user) { create(:user, :account_manager) }

      it "grants the new role" do
        expect(flash[:notice]).to include("granted to")
        expect(user).not_to be_account_manager
        expect(user).to be_administrator
      end
    end

    context "when the role does not exist" do
      let(:role) { "?This%role+will-never|exist]" }
      let(:user) { create(:user) }

      it "does not grant the role" do
        expect(flash[:error]).to include("role was not granted")
        expect(user.user_roles).to be_empty
      end
    end

    context "when the user has an existing facility role" do
      let(:facility) { create(:facility) }
      let(:user) { create(:user, :facility_director, facility: facility) }

      it "grants the global role" do
        expect(flash[:notice]).to include("granted to")
        expect(user).to be_administrator
      end

      it "does not revoke the existing facility role" do
        expect(user).to be_facility_director_of(facility)
      end
    end

    context "when the user already has this global role" do
      let(:user) { create(:user, :administrator) }

      it "retains the user's global role" do
        expect(flash[:notice]).to include("granted to")
        expect(user).to be_administrator
      end
    end
  end
end
