#
# Include in specs for classes that are +AffiliateAccount+s.
# Tests here expect an instance variable +@account_attrs+ to
# exist. +@account_attrs+ should be a +Hash+ of attributes for
# #creating!ing an instance of the class being tested
module AffiliateAccountHelper

  def self.included(base)

    base.context 'affiliates' do

      before :each do
        affiliate=Affiliate.create!(:name => 'Banana Video')
        account_attrs=instance_variable_get(:@account_attrs).merge(:affiliate => affiliate)
        @affiliate_account=described_class.create!(account_attrs)
      end

      it { should validate_presence_of(:affiliate_id) }

      it 'should require affiliate_other if affiliate is other' do
        @affiliate_account.affiliate=Affiliate::OTHER
        @affiliate_account.affiliate_other=nil
        assert !@affiliate_account.save
        @affiliate_account.should ensure_length_of(:affiliate_other).is_at_least(1)
      end

      it 'should not require affiliate_other if affiliate is not other' do
        @affiliate_account.affiliate.should_not be_nil
        @affiliate_account.affiliate.should_not == Affiliate::OTHER
        @affiliate_account.should be_valid
        @affiliate_account.should_not be_new_record
      end

    end

  end

end