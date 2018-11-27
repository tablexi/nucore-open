# frozen_string_literal: true

class AddNoteToPricePolicies < ActiveRecord::Migration[5.0]
  def change
    change_table :price_policies do |t|
      t.string :note, limit: 256
      t.references :created_by, index: true, foreign_key: { to_table: :users }
    end
  end
end
