class DropCanceledFromReservations < ActiveRecord::Migration
  def change
    remove_column :reservations, :canceled_at
    remove_column :reservations, :canceled_by
    remove_column :reservations, :canceled_reason
  end
end
