class AddBillableMinutesToReservations < ActiveRecord::Migration[5.0]
  def change
    add_column :reservations, :billable_minutes, :integer
  end
end
