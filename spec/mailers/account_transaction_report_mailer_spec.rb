# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountTransactionReportMailer do
  context '#csv_report_email' do
    let(:email) { ActionMailer::Base.deliveries.last }
    describe "mailer" do
      let(:report) { double Reports::AccountTransactionsReport, to_csv: "1,2,3\n", description: "test" }

      before :each do
        AccountTransactionReportMailer
          .csv_report_email("recipient@example.net", [1, 2, 3], :statement_date)
          .deliver_now
      end

      context "mail headers" do
        it "has the correct recipient" do
          expect(email.to.first).to eq "recipient@example.net"
        end

        it "has the correct sender" do
          expect(email.from.first).to eq Settings.email.from
        end
      end

      context "mail body" do
        it "has an attachment" do
          expect(email.attachments.count).to eq 1
        end
      end
    end
  end

  # SLOW
  # Commented out because the test is slow
  # context "with over 1000 order details" do

  #   let(:facility) { create(:facility) }
  #   let(:user) { create(:user) }
  #   let(:account) { create(:setup_account, owner: user) }
  #   let(:facility_account) do
  #     FactoryBot.create(:facility_account, facility: facility)
  #   end

  #   let(:item) do
  #     facility
  #       .items
  #       .create(attributes_for(:item, facility_account_id: facility_account.id))
  #   end

  #   let(:order_details) do
  #     Array.new(1001) do
  #       place_product_order(user, facility, item, account)
  #     end
  #   end

  #   it "does not fail" do
  #     expect do
  #       described_class.csv_report_email("recipient@example.net", order_details.map(&:id), :statement_date).deliver
  #     end.to change(ActionMailer::Base.deliveries, :count).by(1)
  #   end
  # end

end
