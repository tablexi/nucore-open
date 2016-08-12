class AddSangerProductGroups < ActiveRecord::Migration

  def change
    create_table :sanger_sequencing_product_groups do |t|
      t.references :product, null: false, foreign_key: true
      t.index :product_id, unique: true
      t.string :group, null: false
      t.timestamps
    end
  end

end
