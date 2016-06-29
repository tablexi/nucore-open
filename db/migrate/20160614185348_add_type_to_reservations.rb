class AddTypeToReservations < ActiveRecord::Migration

  def up
    add_column :reservations, :type, :string
    change_column :reservations, :reserve_end_at, :datetime, null: true
  end

  def down
    Reservation.where.not(type: nil).delete_all
    remove_column :reservations, :type
    change_column :reservations, :reserve_end_at, :datetime, null: false
  end

end
