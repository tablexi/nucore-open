class AddReconciliationDateToOrderDetail < ActiveRecord::Migration
  def up
    add_column :order_details, :reconciled_at, :datetime

    OrderDetail.where(state: "reconciled").find_each do |od|
      if od.statement
        od.update_attribute(:reconciled_at, od.statement.created_at)
      elsif od.journal
        od.update_attribute(:reconciled_at, od.journal.journal_date)
      else
        # TODO: What do we do with these
        od.update_attribute(:reconciled_at, od.reviewed_at)
      end
    end
  end

  def down
    remove_column :order_details, :reconciled_at
  end
end
