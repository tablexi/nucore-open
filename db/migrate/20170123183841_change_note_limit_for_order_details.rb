class ChangeNoteLimitForOrderDetails < ActiveRecord::Migration

  def change
    change_column :order_details, :note, :string, limit: nil
  end

end
