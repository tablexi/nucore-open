require "rails_helper"

RSpec.describe StatementCreator do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:account) { FactoryGirl.create(:nufs_account,
                     account_users_attributes: [FactoryGirl.attributes_for(:account_user, user: user)], type: "CreditCardAccount"
                  ) }
  let(:order_detail_1) { place_and_complete_item_order(user, facility, account, true) }
  let(:order_detail_2) { place_and_complete_item_order(user, facility, account, true) }
  let(:order_detail_3) { place_and_complete_item_order(user, facility, account, false) }

  def initialize_creator
    @creator = described_class.new(order_detail_ids: [order_detail_1.id, order_detail_2.id], session_user: user, current_facility: facility)
  end

  describe "#new" do
    before { initialize_creator }

    it "sets variables" do
      expect(@creator.order_detail_ids).to match_array([order_detail_1.id, order_detail_2.id])
      expect(@creator.session_user).to eq(user)
      expect(@creator.current_facility).to eq(facility)
    end
  end

  describe "#create" do
    before do
      initialize_creator
      @creator.create
    end

    it "sets order details to be statemented" do
      expect(@creator.to_statement).not_to be_empty
      expect(@creator.to_statement.keys.first.id).to eq(account.id)
    end

    it "creates statements" do
      expect(Statement.all.length).to eq(1)
      expect(order_detail_1.reload.statement).not_to be_nil
      expect(order_detail_2.reload.statement).not_to be_nil
    end
  end

  describe "#formatted_errors" do
    before { initialize_creator }

    it "formats the errors with line breaks" do
      @creator.errors = ["Error message", "Another error message"]
      expect(@creator.formatted_errors).to eq("Error message<br/>Another error message")
    end
  end

  describe "#send_statement_emails" do
    before do
      ActionMailer::Base.deliveries.clear
      initialize_creator
      @creator.create
      @creator.send_statement_emails
    end

    context "when statement emailing is on", feature_setting: { send_statement_emails: true } do
      it "sends statements" do
        expect(ActionMailer::Base.deliveries).not_to be_empty
      end
    end

    context "when statement emailing is off", feature_setting: { send_statement_emails: false } do
      it "does not send statements" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end

  describe "#account_list" do
    before do
      initialize_creator
      @creator.create
    end

    it "returns account list items for accounts statemented" do
      expect(@creator.account_list).to match_array([account.account_list_item])
    end
  end

  describe "#formatted_account_list" do
    before do
      initialize_creator
      @creator.account_statements = {}
      @creator.account_statements[account] = "Statement"
    end

    it "returns account list items with line breaks" do
      expect(@creator.formatted_account_list).to eq(account.account_list_item)
    end
  end

end
