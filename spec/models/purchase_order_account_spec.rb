require 'spec_helper'
require 'affiliate_account_helper'

describe PurchaseOrderAccount do
  include AffiliateAccountHelper

  before(:each) do
    @user=Factory.create(:user)

    @owner={
        :user => @user,
        :created_by => @user,
        :user_role => 'Owner'
    }

    @account_attrs={
        :account_number => '4111-1111-1111-1111',
        :description => "account description",
        :expires_at => Time.zone.now + 1.year,
        :created_by => @user,
        :account_users_attributes => [@owner],
    }
  end

end
