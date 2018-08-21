# frozen_string_literal: true

require "rails_helper"
RSpec.describe StatusChangeNotifications do
  before :each do
    @order_status = FactoryBot.create(:order_status)
    Settings.order_details ||= {}
    Settings.order_details.status_change_hooks = {
      :"#{@order_status.downcase_name}" => "StatusChangeNotifications::#{self.class.description}",
    }
    SettingsHelper.enable_feature(:product_specific_contacts)
    @user = FactoryBot.create(:user)
    @facility = FactoryBot.create(:facility, email: "notify-facility@example.org")
    @order_detail = place_and_complete_item_order(@user, @facility)
    @order_detail.product.update_attributes!(contact_email: "notify-product@example.org")
    @initial_order_status = @order_detail.order_status
  end

  context "NotifyFacilityHook" do
    it "should notify the product's email address" do
      notifier_should_receive_email "notify-product@example.org"
    end
  end

  context "NotifyPurchaserHook" do
    it "should notify the purchaser" do
      notifier_should_receive_email @user.email
    end
  end

  private

  def notifier_should_receive_email(email)
    expect(Notifier).to receive(:order_detail_status_change).with(@order_detail, @initial_order_status, @order_status, email).once.and_return(double deliver: true)
    @order_detail.change_status!(@order_status)
  end

end
