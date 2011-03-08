require 'test/test_helper'

class OrderTest < ActiveSupport::TestCase

  setup do
    User.delete_all
  end

  should "have a facility after adding a product to the cart" do
    @user     = Factory.create(:user)
    @cart     = Factory.create(:order, :user_id => @user.id, :created_by => @user.id)
    @facility = Factory.create(:facility)
    @service  = Factory.create(:service, :facility => @facility)
    @cart.add(@service, 1)
    assert_equal @facility, @cart.facility
  end

end