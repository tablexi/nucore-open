class CreatePriceGroupDiscounts < ActiveRecord::Migration[6.1]
  def change
    create_table :price_group_discounts do |t|
      t.references :price_group, type: :integer, foreign_key: true, null: false
      t.references :schedule_rule, type: :integer, foreign_key: true, null: false
      t.decimal :discount_percent

      t.timestamps
    end
  end
end
