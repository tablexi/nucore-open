require "rails_helper"

RSpec.describe SamlAuthentication::SessionsController, type: :controller do
  describe "create" do
    # based on a onelogin response
    let(:attribute_map) do
      {
        "PersonImmutableID" => "username",
        "User.email" => "email",
        "User.FirstName" => "first_name",
        "User.LastName" => "last_name",
      }
    end

    let(:saml_response) do
      Base64.encode64(File.read(File.expand_path("../../fixtures/login_response.xml", __dir__)))
    end

    before do
      request.env["devise.mapping"] = Devise.mappings[:user]
      allow(User).to receive(:attribute_map).and_return(attribute_map)
      # Our response fixure is old, so don't worry about it
      allow(Devise).to receive(:allowed_clock_drift_in_seconds).and_return(1000.years)
    end

    describe "the user does not exist already" do
      it "creates a user" do
        expect { post :create, SAMLResponse: saml_response }.to change(User, :count).by(1)
      end

      it "logs in the user and sets the first/last names" do
        post :create, SAMLResponse: saml_response
        expect(controller.current_user.email).to eq("sst123@example.com")
        expect(controller.current_user.username).to eq("sst123")
        expect(controller.current_user.first_name).to eq("Sam")
        expect(controller.current_user.last_name).to eq("Student")
      end

      it "has no password on the new user" do
        post :create, SAMLResponse: saml_response
        expect(controller.current_user.encrypted_password).to be_nil
      end
    end

    describe "an email-based user exists" do
      let!(:user) { create(:user, email: "sst123@example.com", username: "sst123@example.com") }

      it "does not create a new user" do
        expect { post :create, SAMLResponse: saml_response }.not_to change(User, :count)
      end

      it "logs in the user" do
        post :create, SAMLResponse: saml_response
        expect(controller.current_user).to eq(user)
      end

      it "updates the user's username" do
        post :create, SAMLResponse: saml_response
        expect(user.reload.username).to eq("sst123")
      end

      it "updates the user's first and last name" do
        post :create, SAMLResponse: saml_response
        expect(user.reload.first_name).to eq("Sam")
        expect(user.last_name).to eq("Student")
      end

      it "clears the password" do
        expect { post :create, SAMLResponse: saml_response }.to change { user.reload.encrypted_password }.to(nil)
      end
    end

    describe "the user already exists" do
      let!(:user) { create(:user, username: "sst123", email: "something@old.com") }

      it "does not create a new user" do
        expect { post :create, SAMLResponse: saml_response }.not_to change(User, :count)
      end

      it "logs in the user" do
        post :create, SAMLResponse: saml_response
        expect(controller.current_user).to eq(user)
      end

      it "updates the user's email" do
        post :create, SAMLResponse: saml_response
        expect(user.reload.email).to eq("sst123@example.com")
      end

      it "updates the user's first and last name" do
        post :create, SAMLResponse: saml_response
        expect(user.reload.first_name).to eq("Sam")
        expect(user.last_name).to eq("Student")
      end

      it "clears the password" do
        expect { post :create, SAMLResponse: saml_response }.to change { user.reload.encrypted_password }.to(nil)
      end
    end
  end
end
