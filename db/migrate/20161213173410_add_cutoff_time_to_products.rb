class AddCutoffTimeToProducts < ActiveRecord::Migration

  def change
    add_column :products, :cutoff_time, :integer, null: false, default: 0
  end

end
