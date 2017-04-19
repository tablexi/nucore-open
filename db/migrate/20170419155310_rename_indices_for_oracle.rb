class RenameIndicesForOracle < ActiveRecord::Migration
  def change
    unless NUCore::Database.oracle?
      rename_index :secure_rooms_card_readers, "index_secure_rooms_card_readers_on_product_id", "index_card_readers_on_prod_id"
      rename_index :secure_rooms_card_readers, "index_secure_rooms_card_readers_on_tablet_token", "index_card_rdrs_on_tab_token"
      rename_index :secure_rooms_events, "index_secure_rooms_events_on_user_id", "index_rooms_events_on_user_id"
      rename_index :secure_rooms_events, "index_secure_rooms_events_on_card_reader_id", "index_events_on_card_rdr_id"
    end
  end
end
