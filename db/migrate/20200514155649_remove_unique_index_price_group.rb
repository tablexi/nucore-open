class RemoveUniqueIndexPriceGroup < ActiveRecord::Migration[5.2]
  def change
    remove_foregin_key :price_groups, :facilities
    remove_index :price_groups, name: "index_price_groups_on_facility_id_and_name"
    add_foreign_key :price_groups, :facilities
    add_index(:price_groups, [:facility_id, :name], unique: false, name: "index_price_groups_on_facility_id_and_name")
  end
end
