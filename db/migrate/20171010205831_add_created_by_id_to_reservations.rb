class AddCreatedByIdToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :created_by_id, :integer
    add_foreign_key :reservations, :users, column: :created_by_id
  end
end
