class CreateDefaultPriceGroupsForUsers < ActiveRecord::Migration
  def up
    User.find_each do |user|
      # does nothing if user_based_price_groups is not turned on
      user.create_default_price_group!
    end
  end
  def down
    UserPriceGroupMember.where(price_group: [PriceGroup.base, PriceGroup.external]).delete_all
  end
end
