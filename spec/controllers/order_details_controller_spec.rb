require "rails_helper"

RSpec.describe OrderDetailsController do
  let(:order) { order_detail.order }
  let(:order_detail) { reservation.order_detail }
  let(:reservation) { create(:purchased_reservation) }
  let(:user) { order_detail.user }

  describe "#dispute" do
    let(:params) { { order_id: order.id, id: order_detail.id } }
    before { sign_in user }

    context "when the order is not disputable" do
      before { put :dispute, params }

      it { expect(response.code).to eq("404") }
    end

    context "when the order is disputable" do
      before(:each) do
        order_detail.update_attributes!(state: "complete", reviewed_at: 7.days.from_now)
        put :dispute, params.merge(order_detail: { dispute_reason: dispute_reason })
      end

      context "with a blank dispute_reason" do
        let(:dispute_reason) { "" }

        it { expect(order_detail.reload).not_to be_disputed }
      end

      context "with a dispute_reason" do
        let(:dispute_reason) { "Too expensive" }

        it { expect(order_detail.reload).to be_disputed }

        it "captures who disputed it" do
          expect(order_detail.reload.dispute_by).to eq(user)
        end
      end
    end
  end

  describe "#show" do
    before(:each) do
      sign_in user
      get :show, order_id: order.id, id: order_detail.id
    end

    context "when logged in as the user who owns the order" do
      it { expect(response).to access_the_page }
    end

    context "when logged in as a user that does not own the order" do
      let(:user) { create(:user) }

      it { expect(response.code).to eq("403") }
    end
  end

  describe "#cancel" do
    context "when the order is a reservation" do
      context "when attempting to cancel the reservation" do
        before { sign_in user }

        context "and the reservation is cancelable" do
          before(:each) do
            expect(reservation).to be_can_cancel
            put :cancel, order_id: order.id, id: order_detail.id
          end

          it { expect(order_detail.reload).to be_canceled }
        end

        context "and the reservation is not cancelable" do
          before do
            reservation.update_attributes(actual_start_at: Time.current)
            put :cancel, order_id: order.id, id: order_detail.id
          end

          it { expect(order_detail.reload).not_to be_canceled }
          it { expect(response.code).to eq("404") }
        end
      end
    end
  end

  describe "edit/update" do
    shared_examples_for "allows the proper users" do
      describe "as the account owner" do
        let(:signed_in_user) { order_detail.account.owner_user }
        before { perform }

        it "succeeds" do
          expect(response).to access_the_page
        end
      end

      describe "as a business admin" do
        let(:signed_in_user) { FactoryGirl.create(:user) }
        before do
          FactoryGirl.create(:account_user, :business_administrator,
                             user: signed_in_user, account: order_detail.account)
          perform
        end

        it "succeeds" do
          expect(response).to access_the_page
        end
      end

      describe "as an account purchaser" do
        let(:signed_in_user) { FactoryGirl.create(:user) }
        before do
          FactoryGirl.create(:account_user, :purchaser,
                             user: signed_in_user, account: order_detail.account)
          perform
        end

        it "does not load" do
          expect(response.code).to eq("403")
        end
      end

      describe "as the purchaser" do
        let(:signed_in_user) { FactoryGirl.create(:user) }
        before do
          FactoryGirl.create(:account_user, :purchaser,
                             user: signed_in_user, account: order_detail.account)
          order.update_attributes(user: signed_in_user)
          perform
        end

        it "succeeds" do
          expect(response).to access_the_page
        end
      end

      describe "as a random user" do
        let(:signed_in_user) { FactoryGirl.create(:user) }
        before { perform }

        it "does not load" do
          expect(response.code).to eq("403")
        end
      end
    end

    describe "#edit" do
      def perform
        sign_in signed_in_user
        get :edit, order_id: order.id, id: order_detail.id
      end

      it_behaves_like "allows the proper users"
    end

    describe "#update" do
      # need some params to satisfy strong params
      let(:params) { { field: "dummy" } }
      def perform
        sign_in signed_in_user
        put :update, order_id: order.id, id: order_detail.id, order_detail: params
      end

      it_behaves_like "allows the proper users"

      describe "updating the account" do
        let(:signed_in_user) { user }
        let(:account2) { FactoryGirl.create(:setup_account, owner: user) }
        let(:params) { { account_id: account2.id } }

        shared_examples_for "changes the account" do
          it "changes the account" do
            expect { perform }.to change { order_detail.reload.account }.to(account2)
          end
        end

        shared_examples_for "does not change the account" do
          it "does not change the account" do
            expect { perform }.not_to change { order_detail.reload.account }
          end
        end

        describe "before completion" do
          it_behaves_like "changes the account"
        end

        describe "after completion" do
          let(:reservation) { FactoryGirl.create(:completed_reservation) }

          describe "while in the review period" do
            before { order_detail.update_attributes!(reviewed_at: 7.days.from_now) }
            it_behaves_like "changes the account"
          end

          describe "when the review period is over" do
            before { order_detail.update_attributes!(reviewed_at: 1.day.ago) }
            it_behaves_like "does not change the account"
          end

          describe "when the review period is over, but it is being disputed" do
            before { order_detail.update_attributes!(reviewed_at: 1.day.ago, dispute_at: 2.days.ago, dispute_reason: "reason") }
            it_behaves_like "changes the account"
          end

          describe "when the dispute has been resolved" do
            before { order_detail.update_attributes!(reviewed_at: 1.day.ago, dispute_at: 2.days.ago, dispute_resolved_at: Time.current, dispute_reason: "reason", dispute_resolved_reason: "notes") }
            it_behaves_like "does not change the account"
          end
        end

        describe "a canceled reservation" do
          before do
            order_detail.update_order_status!(user, OrderStatus.canceled_status)
          end
          it_behaves_like "does not change the account"
        end
      end

      describe "does not update other fields" do
        let(:signed_in_user) { user }
        let(:params) { { actual_cost: 113, product_id: 999, user_id: 111, dispute_reason: "Dispute" } }

        it "is successful, but does not change any fields" do
          expect { perform }.not_to change { order_detail.reload.attributes }
          expect(response).to be_redirect
        end
      end
    end
  end
end
