# frozen_string_literal: true

class AddExpiresMinutesBeforeToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :expires_mins_before, :integer
  end
end
