# frozen_string_literal: true

RSpec.shared_examples_for "AccountBuilder#build" do
  subject(:account) { builder.build }
  let(:builder) { described_class.new(options) }
  let(:facility) { FactoryBot.build_stubbed(:facility) }
  let(:user) { FactoryBot.build_stubbed(:user) }

  context "when the affiliate_id param is set" do
    let(:affiliate) { Affiliate.create!(name: "New Affiliate") }
    let(:affiliate_other) { "" }

    it "sets the affiliate", :aggregate_failures do
      expect(account.affiliate).to eq(affiliate)
      expect(account.affiliate_other).to be_blank
    end

    context "when the affiliate selected is 'Other'" do
      let(:affiliate) { Affiliate.OTHER }

      context "and the affiliate_other param is set" do
        let(:affiliate_other) { "Other Affiliate" }

        it "sets affiliate_other", :aggregate_failures do
          expect(account.affiliate).to eq(affiliate)
          expect(account.affiliate_other).to eq("Other Affiliate")
        end
      end
    end

    context "when the affiliate supports subaffiliates" do
      before { affiliate.update_attribute(:subaffiliates_enabled, true) }

      context "and the affiliate_other param is set" do
        let(:affiliate_other) { "Affiliate Category" }

        it "sets affiliate_other", :aggregate_failures do
          expect(account.affiliate).to eq(affiliate)
          expect(account.affiliate_other).to eq("Affiliate Category")
        end
      end
    end
  end

  context "when the affiliate_id param is not set" do
    let(:affiliate) { nil }
    let(:affiliate_other) { "" }

    it "does not set the affiliate", :aggregate_failures do
      expect(account.affiliate).to be_blank
      expect(account.affiliate_other).to be_blank
    end
  end
end
