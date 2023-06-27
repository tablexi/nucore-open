# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Resolving a disputed order" do
  class OrderDetail < ApplicationRecord
    def global_admin_must_resolve?
      true
    end
  end

  let(:item) { create(:setup_item) }
  let(:facility) { item.facility }
  let(:owner) { create(:user) }
  let(:administrator) { create(:user, :administrator) }
  let(:facility_admin) { create(:user, :facility_director, facility:) }
  let(:account) { create(:account, :with_account_owner, owner:) }
  let(:order) { create(:complete_order, product: item, account:) }
  let(:logged_in_user) { nil }

  let(:order_detail) do
    od = order.order_details.first
    od.update(
      reviewed_at: 5.days.ago,
      dispute_at: 3.days.ago,
      dispute_by: owner,
      dispute_reason: "Testing, testing"
    )
    od
  end

  before do
    login_as logged_in_user
    visit facility_disputed_orders_path facility
    click_link order_detail.id.to_s
  end

  context "logged in as global administrator" do
    let(:logged_in_user) { administrator }

    it "allows global admins to resolve a disputed order" do
      expect(page).to have_content "Resolution Notes"
    end
  end

  context "logged in as user who is not a global administrator" do
    let(:logged_in_user) { facility_admin }

    it "does not allow non-global admins to resolve a disputed order" do
      expect(page).to have_content I18n.t("order_details.notices.global_admin_must_resolve.alert")
    end
  end
end
