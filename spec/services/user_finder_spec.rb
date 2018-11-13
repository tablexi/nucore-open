# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserFinder do
  describe ".search" do
    it "finds users by first_name" do
      first_name = SecureRandom.hex(8)
      user = FactoryBot.create(:user, first_name: first_name)
      found_users = UserFinder.search(first_name, nil).first
      expect(found_users).to include(user)
    end

    it "finds users by last_name" do
      last_name = SecureRandom.hex(8)
      user = FactoryBot.create(:user, last_name: last_name)
      found_users = UserFinder.search(last_name, nil).first
      expect(found_users).to include(user)
    end

    it "finds users by username" do
      username = SecureRandom.hex(8)
      user = FactoryBot.create(:user, username: username)
      found_users = UserFinder.search(username, nil).first
      expect(found_users).to include(user)
    end

    it "finds users by their first_name and last_name joined together" do
      first_name = SecureRandom.hex(8)
      last_name = SecureRandom.hex(8)
      user = FactoryBot.create(:user, first_name: first_name, last_name: last_name)
      found_users = UserFinder.search([first_name, last_name].join, nil).first
      expect(found_users).to include(user)
    end

    it "finds users by email" do
      email = "#{SecureRandom.hex(8)}@example.com"
      user = FactoryBot.create(:user, email: email)
      found_users = UserFinder.search(email, nil).first
      expect(found_users).to include(user)
    end
  end
end
