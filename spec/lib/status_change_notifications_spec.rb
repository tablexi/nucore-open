require 'spec_helper'
describe StatusChangeNotifications do
  before :each do
    @order_status = Factory.create(:order_status)
    if Settings.order_details
      Settings.order_details.status_change_hooks = {
        :"#{@order_status.downcase_name}" => "StatusChangeNotifications::#{self.class.description}"
      }
    end
    @user = Factory.create(:user)
    @facility = Factory.create(:facility, :email => 'notify-facility@example.org')
    @order_detail = place_and_complete_item_order(@user, @facility)
    @order_detail.product.update_attributes!(:contact_email => 'notify-product@example.org')
    @initial_order_status = @order_detail.order_status
  end

  context 'NotifyFacilityHook' do
    it "should notify the product's email address" do
      notifier_expects_email 'notify-product@example.org'
    end
  end

  context 'NotifyPurchaserHook' do
    it 'should notify the purchaser' do
      notifier_expects_email @user.email
    end
  end

  private

  def notifier_expects_email(email)
    Notifier.expects(:order_detail_status_change).with(@order_detail, @initial_order_status, @order_status, email).once.returns(stub(:deliver => true))
    @order_detail.change_status!(@order_status)
  end
  
end