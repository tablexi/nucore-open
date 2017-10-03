class AddCreatedByToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :created_by, :integer
  end
end
