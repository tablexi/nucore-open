# frozen_string_literal: true

class AddShowDetailsToInstruments < ActiveRecord::Migration

  def self.up
    change_table :products do |t|
      t.boolean :show_details, default: false, null: false
    end
  end

  def self.down
    change_table :products do |t|
      t.remove :show_details
    end
  end

end
