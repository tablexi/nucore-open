class AddFullTextIndexToProducts < ActiveRecord::Migration
  def change
    add_index :products, [:name, :description], type: :fulltext
  end
end
