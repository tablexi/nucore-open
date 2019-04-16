class AddIndexToInstrumentStatuses < ActiveRecord::Migration[5.0]
  def change
    add_index :instrument_statuses, [:instrument_id, :created_at]
  end
end
