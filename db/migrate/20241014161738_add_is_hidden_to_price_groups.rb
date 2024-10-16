class AddIsHiddenToPriceGroups < ActiveRecord::Migration[7.0]
  def up
    add_column :price_groups, :is_hidden, :boolean, default: false

    PriceGroup.reset_column_information
    PriceGroup.update_all(is_hidden: false)

    change_column_null :price_groups, :is_hidden, false
  end

  def down
    remove_column :price_groups, :is_hidden
  end
end
