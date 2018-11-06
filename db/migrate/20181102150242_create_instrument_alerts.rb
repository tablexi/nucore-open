# frozen_string_literal: true

class CreateInstrumentAlerts < ActiveRecord::Migration[5.0]
  def change
    create_table :instrument_alerts do |t|
      t.belongs_to :instrument, null: false, index: true
      t.string :note, limit: 256, null: false
      t.timestamps
    end
  end
end
