module NotificationsHelper

  def create_merge_notification_subject
    @facility       ||= FactoryGirl.create(:facility)
    @facility_account ||= @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @user           ||= FactoryGirl.create(:user)
    @item           ||= @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))

    place_product_order @user, @facility, @item
    clone=@order.dup
    assert clone.save
    @order.update_attribute :merge_with_order_id, clone.id
    @order_detail.reload
  end

end
