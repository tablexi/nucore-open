class AddAdminNoteToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :admin_note, :string
  end
end
