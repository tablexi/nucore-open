# frozen_string_literal: true

class AddOutsideUserToPurchaseOrder < ActiveRecord::Migration

  def change
    change_table :accounts do |t|
      t.string :outside_contact_info
    end
  end

end
