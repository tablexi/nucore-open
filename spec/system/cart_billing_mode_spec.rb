# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding products with different billing modes to cart" do
  let(:facility) { create(:setup_facility) }
  let!(:nonbillable_item) { create(:setup_item, facility:, billing_mode: "Nonbillable") }
  let!(:default_item) { create(:setup_item, facility:, billing_mode: "Default") }
  let(:skip_review_item) { create(:setup_item, facility:, billing_mode: "Skip Review") }

  let!(:internal_account) { create(:purchase_order_account, :with_account_owner, facility:) }
  let!(:external_account) { create(:purchase_order_account, :with_account_owner, owner: external_user, facility:) }

  let(:internal_user) { internal_account.owner.user }
  let(:external_user) { create(:user, :external) }

  # not sure we should be doing these
  let!(:internal_account_price_group_member) { create(:account_price_group_member, account: internal_account, price_group: PriceGroup.base) }
  let!(:internal_account_price_group_member_2) { create(:account_price_group_member, account: internal_account, price_group: PriceGroup.external) }

  let!(:default_price_policy) { create(:item_price_policy, price_group: PriceGroup.base, product: default_item) }
  let!(:default_price_policy_2) { create(:item_price_policy, price_group: PriceGroup.external, product: default_item) }

  before do
    create(:account_user, :purchaser, account: internal_account, user: external_user)
    create(:account_user, :purchaser, account: external_account, user: internal_user)
  end

  ### SHARED EXAMPLES ###
  shared_examples "user with no accounts" do
    before(:each) do
      u = logged_in_user
      u.account_users.each(&:destroy)
      u.save
      u.reload
    end

    before do
      login_as logged_in_user
    end

    it "allows a user without any accounts to add a nonbillable product to cart" do
      visit facility_item_path(facility, nonbillable_item)
      click_on "Add to cart"
      expect(page).to have_content(nonbillable_item.name)
    end

    it "does not allow a user without any accounts to add a Skip Review product to cart" do
      visit facility_item_path(facility, skip_review_item)
      expect(page).to have_content("Sorry, but we could not find a valid payment source that you can use to purchase this")
    end

    it "does not allow a user without any accounts to add a default product to cart" do
      visit facility_item_path(facility, default_item)
      if price_groups_present
        expect(page).to have_content("Sorry, but we could not find a valid payment source that you can use to purchase this")
      else
        expect(page).to have_content("You are not in a price group that may purchase this")
      end
    end
  end

  shared_examples "adding item to cart" do
    before do
      login_as logged_in_user
    end

    it "can add Skip Review item to cart" do
      visit facility_item_path(facility, skip_review_item)
      click_on "Add to cart"
      choose account_used.to_s
      click_button "Continue"
      expect(page).to have_content(skip_review_item.name)
    end

    it "can add Nonbillable item to cart" do
      visit facility_item_path(facility, nonbillable_item)
      click_on "Add to cart"
      expect(page).to have_content(nonbillable_item.name)
    end

    # it "can add a default item to cart" do
    #   visit facility_item_path(facility, default_item)
    #   click_on "Add to cart"
    #   choose account_used.to_s
    #   click_button "Continue"
    #   expect(page).to have_content(default_item.name)
    # end
  end

  ### SPEC CONTEXTS ###
  context "with user-based price groups disabled", feature_setting: { user_based_price_groups: false } do
    context "when a user has no price groups (or no account with price groups)" do
      it_behaves_like "user with no accounts" do
        let(:logged_in_user) { internal_user }
        let(:price_groups_present) { false }
      end
    end

    context "with an external user that has no account" do
      it_behaves_like "user with no accounts" do
        let(:logged_in_user) { external_user }
        let(:price_groups_present) { false }
      end
    end
  end

  context "with user-based price groups enabled", feature_setting: { user_based_price_groups: true } do
    context "with an internal that has no account" do
      it_behaves_like "user with no accounts" do
        let(:logged_in_user) { internal_user }
        let(:price_groups_present) { true }
      end
    end

    context "with an external user that has no account" do
      it_behaves_like "user with no accounts" do
        let(:logged_in_user) { external_user }
        let(:price_groups_present) { true }
      end
    end

    context "internal user and internal account" do
      it_behaves_like "adding item to cart" do
        let(:logged_in_user) { internal_user }
        let(:account_used) { internal_account }
      end
    end

    context "internal user and external account" do
      it_behaves_like "adding item to cart" do
        let(:logged_in_user) { internal_user }
        let(:account_used) { external_account }
      end
    end

    context "external user and external account" do
      it_behaves_like "adding item to cart" do
        let(:logged_in_user) { external_user }
        let(:account_used) { external_account }
      end
    end

    context "external user and internal account" do
      it_behaves_like "adding item to cart" do
        let(:logged_in_user) { external_user }
        let(:account_used) { internal_account }
      end
    end
  end
end
