# frozen_string_literal: true

require "rails_helper"

RSpec.describe Facility do
  context "can_pay_with_account?" do
    before :each do
      @facility = FactoryBot.create(:facility)
      owner = FactoryBot.create(:user)
      @owner_attrs = [{
        user: owner,
        created_by: owner.id,
        user_role: "Owner",
      }]
    end

    context "purchase orders" do
      before :each do
        @account = FactoryBot.create(:purchase_order_account, account_users_attributes: @owner_attrs)
      end

      it "should return false if facility does not accept po and account is po" do
        @facility.accepts_po = false
        expect(@facility.can_pay_with_account?(@account)).to be false
      end

      it "should return true if facility accepts po and account is po" do
        @facility.accepts_po = true
        expect(@facility.can_pay_with_account?(@account)).to be true
      end
    end

    context "credit cards" do
      before :each do
        @account = FactoryBot.create(:credit_card_account, account_users_attributes: @owner_attrs)
      end

      it "should return false if facility does not accept cc and account is cc" do
        @facility.accepts_cc = false
        expect(@facility.can_pay_with_account?(@account)).to be false
      end

      it "should return true if facility accepts cc and account is cc" do
        @facility.accepts_cc = true
        expect(@facility.can_pay_with_account?(@account)).to be true
      end
    end
  end
end
