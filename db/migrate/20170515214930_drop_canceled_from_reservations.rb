# frozen_string_literal: true

class DropCanceledFromReservations < ActiveRecord::Migration
  def change
    remove_column :reservations, :canceled_at, :datetime
    remove_column :reservations, :canceled_by, :integer
    remove_column :reservations, :canceled_reason, :string
  end
end
