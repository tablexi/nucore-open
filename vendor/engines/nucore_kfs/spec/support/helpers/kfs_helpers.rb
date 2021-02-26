# frozen_string_literal: true

# Simulates placing an order for an item and having it marked complete
# [_ordered_by_]
#   The user who is ordering the item
# [_facility_]
#   The facility with which the order is placed
# [_account_]
#   The account under which the order is placed
# [_reviewed_]
#   true if the completed order should also be marked as reviewed, false by default
def place_and_complete_kfs_item_order(ordered_by, facility, account = nil, reviewed = false)
  @facility_account = FactoryBot.create(:kfs_facility_account, facility: facility)
  @item = facility.items.create(FactoryBot.attributes_for(:item, facility_account_id: @facility_account.id))
  place_product_order(ordered_by, facility, @item, account)

  # act like the parent order is valid
  @order.state = "validated"

  # purchase it
  @order.purchase!

  @order_detail.change_status!(OrderStatus.complete)

  od_attrs = {
    actual_cost: 20,
    actual_subsidy: 10,
    price_policy_id: @item_pp.id,
  }

  od_attrs[:reviewed_at] = Time.zone.now - 1.day if reviewed
  @order_detail.update_attributes(od_attrs)
  @order_detail
end