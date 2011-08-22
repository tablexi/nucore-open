require 'spec_helper'
require 'affiliate_account_helper'

describe CreditCardAccount do
  include AffiliateAccountHelper
  
  before(:each) do
    @user=Factory.create(:user)

    @owner={
      :user => @user,
      :created_by => @user,
      :user_role => 'Owner'
    }

    @account_attrs={
      :expiration_month => 1,
      :expiration_year => (Time.zone.now + 1.year).year,
      :expires_at => Time.zone.now + 1.year,
      :description => "account description",
      :name_on_card => 'Person',
      :created_by => @user,
      :account_users_attributes => [@owner]
    }
  end

  context "valid credit card number" do
#    it "should mask VISA correctly" do
#      @options[:account_number] = '4111-1111-1111-1111'
#      @card = CreditCardAccount.create(@options)
#      assert @card.valid?
#      assert_equal 'xxxx-xxxx-xxxx-1111', @card.account_number
#      assert_equal '4111-1111-1111-1111', @card.credit_card_number
#
#      @options[:account_number] = '4111111111111111'
#      @card = CreditCardAccount.create(@options)
#      assert @card.valid?
#      assert_equal 'xxxx-xxxx-xxxx-1111', @card.account_number
#      assert_equal '4111-1111-1111-1111', @card.credit_card_number
#    end
#
#    it "should mask MasterCard correctly" do
#      @options[:account_number] = '5555-5555-5555-4444'
#      @card = CreditCardAccount.create(@options)
#      assert @card.valid?
#      assert_equal 'xxxx-xxxx-xxxx-4444', @card.account_number
#      assert_equal '5555-5555-5555-4444', @card.credit_card_number
#    end
#
#    it "should mask AMEX correctly" do
#      @options[:account_number] = '3782 822463 10005'
#      @card = CreditCardAccount.create(@options)
#      assert @card.valid?
#      assert_equal 'xxxx-xxxxxx-x0005', @card.account_number
#      assert_equal '3782-822463-10005', @card.credit_card_number
#    end
#
#    it "should be a valid credit card number" do
#      @options[:account_number] = '1234-1234-1234-1234'
#      @card = CreditCardAccount.create(@options)
#      assert !@card.valid?
#      assert @card.errors[:account_number]
#    end
  end
end
