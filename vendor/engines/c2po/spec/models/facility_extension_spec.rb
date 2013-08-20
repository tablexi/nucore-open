require 'spec_helper'

describe Facility do

  context 'can_pay_with_account?' do

    before :each do
      @facility=FactoryGirl.create(:facility)
      owner=FactoryGirl.create(:user)
      @owner_attrs=[{
        :user => owner,
        :created_by => owner.id,
        :user_role => 'Owner'
      }]
    end

    context 'purchase orders' do
      before :each do
        @account=FactoryGirl.create(:purchase_order_account, :account_users_attributes => @owner_attrs)
      end

      it 'should return false if facility does not accept po and account is po' do
        @facility.accepts_po=false
        @facility.can_pay_with_account?(@account).should be_false
      end

      it 'should return true if facility accepts po and account is po' do
        @facility.accepts_po=true
        @facility.can_pay_with_account?(@account).should be_true
      end
    end


    context 'credit cards' do
      before :each do
        @account=FactoryGirl.create(:credit_card_account, :account_users_attributes => @owner_attrs)
      end

      it 'should return false if facility does not accept cc and account is cc' do
        @facility.accepts_cc=false
        @facility.can_pay_with_account?(@account).should be_false
      end

      it 'should return true if facility accepts cc and account is cc' do
        @facility.accepts_cc=true
        @facility.can_pay_with_account?(@account).should be_true
      end
    end

  end

end