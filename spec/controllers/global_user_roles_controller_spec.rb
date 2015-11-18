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
        expect(flash[:notice]).to be_present
        expect(user_with_roles_to_destroy).not_to be_administrator
      end
    end

    context "when attempting to remove global roles from itself" do
      let(:user_with_roles_to_destroy) { user }

      it "removes no global administrator roles" do
        expect(flash[:error]).to be_present
        expect(administrators).to all be_administrator
      end
    end
  end
end
