class ChangeNoteLimitForOrderDetails < ActiveRecord::Migration

  def up
    add_column :order_details, :temp_note, :text
    OrderDetail.all.each { |od| od.update_attribute(:temp_note, od.note) }
    remove_column :order_details, :note
    rename_column :order_details, :temp_note, :note
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
