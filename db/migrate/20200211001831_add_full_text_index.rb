class AddFullTextIndex < ActiveRecord::Migration[5.2]
  def change
    if NUCore::Database.oracle?
      # TODO
    else
      add_index :products, [:name, :description], type: :fulltext
    end
  end
end
