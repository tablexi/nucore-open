# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionsController do
  let(:params) { {} }
  let(:product) { FactoryBot.create(:setup_item, :with_facility_account) }
  let(:user) { FactoryBot.create(:user) }

  describe "GET #in_review", billing_review_period: 7.days do

    before(:each) do
      sign_in user
      get action, params: params
    end

    let(:action) { :in_review }

    context "when the user owns multiple accounts" do
      let!(:accounts) do
        FactoryBot.create_list(:setup_account,
                               2,
                               :with_order,
                               product: product,
                               owner: user)
      end
      let(:order_details) { accounts.flat_map(&:order_details) }

      before(:each) do
        order_details.each do |order_detail|
          order_detail.reviewed_at = reviewed_at
          order_detail.to_complete!
        end
      end

      context "when reviewed_at is in the future" do
        let(:reviewed_at) { 1.day.from_now }

        it "sets order_details to orders in review from all owned accounts", :aggregate_failures do
          expect(assigns(:order_details)).to match_array(order_details)
          expect(assigns(:recently_reviewed)).to be_empty
        end
      end

      context "when reviewed_at is in the past" do
        let(:reviewed_at) { 1.day.ago }

        it "sets recently_reviewed to orders reviewed from all owned accounts", :aggregate_failures do
          expect(assigns(:order_details)).to be_empty
          expect(assigns(:recently_reviewed)).to eq(order_details)
        end
      end

    end

  end
end
