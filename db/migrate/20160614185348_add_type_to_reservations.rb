class AddTypeToReservations < ActiveRecord::Migration

  def change
    add_column :reservations, :type, :string
    change_column :reservations, :reserve_end_at, :datetime, null: true
  end

end
