# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ability do
  subject(:ability) { Ability.new(user, facility) }
  let(:facility) { FactoryBot.create(:facility) }

  describe "facility staff" do
    let(:user) { FactoryBot.create(:user, :staff, facility: facility) }

    it_is_allowed_to([:index, :dashboard, :tab_counts], SecureRooms::Occupancy)
    it_is_not_allowed_to([:show_problems, :assign_price_policies_to_problem_orders], SecureRooms::Occupancy)
  end

  describe "facility senior staff" do
    let(:user) { FactoryBot.create(:user, :senior_staff, facility: facility) }

    it_is_allowed_to([:index, :dashboard, :tab_counts], SecureRooms::Occupancy)
    it_is_not_allowed_to([:show_problems, :assign_price_policies_to_problem_orders], SecureRooms::Occupancy)
  end

  describe "facility administrator" do
    let(:user) { FactoryBot.create(:user, :facility_administrator, facility: facility) }

    it_is_allowed_to([:index, :dashboard, :tab_counts, :show_problems,
                      :assign_price_policies_to_problem_orders], SecureRooms::Occupancy)
  end

  describe "facility director" do
    let(:user) { FactoryBot.create(:user, :facility_director, facility: facility) }
    it_is_allowed_to([:index, :dashboard, :tab_counts, :show_problems,
                      :assign_price_policies_to_problem_orders], SecureRooms::Occupancy)
  end

  describe "unprivileged user" do
    let(:user) { FactoryBot.create(:user) }

    it_is_not_allowed_to([:index, :dashboard, :tab_counts, :show_problems,
                          :assign_price_policies_to_problem_orders], SecureRooms::Occupancy)
  end
  describe "account manager" do
    let(:user) { FactoryBot.create(:user, :account_manager) }

    it_is_not_allowed_to([:index, :dashboard, :tab_counts, :show_problems,
                          :assign_price_policies_to_problem_orders], SecureRooms::Occupancy)
  end

  describe "billing admin" do
    let(:user) { FactoryBot.create(:user, :billing_administrator) }

    it_is_not_allowed_to([:index, :dashboard, :tab_counts, :show_problems,
                          :assign_price_policies_to_problem_orders], SecureRooms::Occupancy)
  end

  describe "global admin" do
    let(:user) { FactoryBot.create(:user, :administrator) }

    it_is_allowed_to([:index, :dashboard, :tab_counts, :show_problems,
                      :assign_price_policies_to_problem_orders], SecureRooms::Occupancy)
  end
end
