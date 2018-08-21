# frozen_string_literal: true

#
# Include in specs for classes that are +AffiliateAccount+s.
# Tests here expect an instance variable +@account_attrs+ to
# exist. +@account_attrs+ should be a +Hash+ of attributes for
# #creating!ing an instance of the class being tested
module AffiliateAccountHelper

  def self.included(base)
    base.context "affiliates" do

      before :each do
        affiliate = Affiliate.create!(name: "Banana Video")
        account_attrs = instance_variable_get(:@account_attrs).merge(affiliate: affiliate)
        @affiliate_account = described_class.create!(account_attrs)
      end

      it { is_expected.to validate_presence_of(:affiliate_id) }

      it "requires affiliate_other if affiliate is 'Other'" do
        @affiliate_account.affiliate = Affiliate.OTHER
        @affiliate_account.affiliate_other = nil
        assert !@affiliate_account.save
        expect(@affiliate_account)
          .to validate_length_of(:affiliate_other).is_at_least(1)
      end

      it "does not require affiliate_other if affiliate is not 'Other'" do
        expect(@affiliate_account.affiliate).to be_present
        expect(@affiliate_account.affiliate).not_to be_other
        expect(@affiliate_account).to be_valid
        expect(@affiliate_account).not_to be_new_record
      end

    end
  end

end
