require "rails_helper"

RSpec.describe Devise::SessionsController do
  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "#create, aka logging in" do
    describe "a user with the password in the database" do
      let(:user) { FactoryGirl.create(:user, password: "password") }

      specify "can log in" do
        post :create, user: { username: user.username, password: "password" }
        expect(controller.current_user).to eq(user)
      end
    end

    describe "a deactived user" do
      let(:user) { FactoryGirl.create(:user, password: "password", deactivated_at: 1.minute.ago) }

      specify "can not log in" do
        post :create, user: { username: user.username, password: "password" }
        expect { controller.current_user }.to throw_symbol(:warden)
      end
    end
  end
end
