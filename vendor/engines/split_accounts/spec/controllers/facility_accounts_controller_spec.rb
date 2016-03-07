require "rails_helper"
require_relative "../split_accounts_spec_helper"

RSpec.describe FacilityAccountsController, :enable_split_accounts do
  render_views

  let(:facility) { FactoryGirl.create(:setup_facility) }
  before { sign_in user }

  describe "as an admin" do
    let(:user) { FactoryGirl.create(:user, :administrator) }

    describe "default new" do
      before { get :new, facility_id: facility.url_name, owner_user_id: user.id }

      it "sees split account option" do
        expect(response.code).to eq("200")
        expect(response.body).to include("Chart String")
        expect(response.body).to include("Split Account")
      end
    end

    describe "new on split accounts" do
      before { get :new, facility_id: facility.url_name, owner_user_id: user.id, account_type: "SplitAccounts::SplitAccount" }

      it "renders successfully" do
        expect(response.code).to eq("200")
        expect(response.body).to include("Account Number")
        expect(response.body).to include("Add another subaccount")
      end

      it "assigns the correct type of account" do
        expect(assigns(:account)).to be_a(SplitAccounts::SplitAccount)
      end
    end

    describe "show" do
      let(:split_account) { FactoryGirl.create(:split_account) }

      before { get :show, facility_id: facility.url_name, id: split_account.id }

      it "includes edit/suspend buttons" do
        expect(response.body).to include("Edit")
        expect(response.body).to include("Suspend")
      end
    end

    describe "edit" do
      let(:split_account) { FactoryGirl.create(:split_account) }
      before { get :edit, facility_id: facility.url_name, id: split_account.id }

      it "has only the description field" do
        expect(response.body).to include("Description")
        expect(response.body).not_to include("Account Number")
        expect(response.body).not_to include("Add another subaccount")
      end
    end

    describe "update" do
      let(:split_account) { FactoryGirl.create(:split_account) }
      before { post :update, facility_id: facility.url_name, id: split_account.id, split_accounts_split_account: { description: "New Description" } }

      it "updates the description" do
        expect(split_account.reload.description).to eq("New Description")
      end
    end
  end

  describe "as a facility administrator" do
    let(:user) { FactoryGirl.create(:user, :facility_administrator, facility: facility) }

    describe "default new" do
      before { get :new, facility_id: facility.url_name, owner_user_id: user.id }

      it "does not see split account option" do
        expect(response.code).to eq("200")
        expect(response.body).to include("Chart String")
        expect(response.body).not_to include("Split Account")
      end
    end

    describe "new on split accounts" do
      before { get :new, facility_id: facility.url_name, owner_user_id: user.id, account_type: "SplitAccounts::SplitAccount" }

      it "falls back to the default account type" do
        expect(assigns(:account)).to be_a(NufsAccount)
      end
    end

    describe "show" do
      let(:split_account) { FactoryGirl.create(:split_account) }

      before { get :show, facility_id: facility.url_name, id: split_account.id }

      it "does not show the edit/suspend buttons" do
        expect(response.body).not_to include("Edit")
        expect(response.body).not_to include("Suspend")
      end
    end

    describe "edit" do
      let(:split_account) { FactoryGirl.create(:split_account) }
      before { get :edit, facility_id: facility.url_name, id: split_account.id }

      it "returns a 403" do
        expect(response.code).to eq("403")
      end
    end

    describe "update" do
      let(:split_account) { FactoryGirl.create(:split_account) }
      before { post :update, facility_id: facility.url_name, id: split_account.id }

      it "returns a 403" do
        expect(response.code).to eq("403")
      end
    end
  end
end
