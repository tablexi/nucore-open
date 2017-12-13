module NotificationsHelper

  def create_merge_notification_subject
    @facility ||= FactoryBot.create(:facility)
    @facility_account ||= @facility.facility_accounts.create(FactoryBot.attributes_for(:facility_account))
    @user           ||= FactoryBot.create(:user)
    @item           ||= @facility.items.create(FactoryBot.attributes_for(:item, facility_account_id: @facility_account.id))

    place_product_order @user, @facility, @item
    clone = @order.dup
    assert clone.save
    @order.update_attribute :merge_with_order_id, clone.id
    @order_detail.reload
  end

end
