class AddTabletTokenToCardReaders < ActiveRecord::Migration

  class SecureRooms::CardReader < ActiveRecord::Base
  end

  def change
    add_column :secure_rooms_card_readers, :tablet_token, :string
    if NUCore::Database.oracle?
      add_index :secure_rooms_card_readers, :tablet_token, unique: true, name: "index_card_rdrs_on_tab_token"
    else
      add_index :secure_rooms_card_readers, :tablet_token, unique: true
    end

    SecureRooms::CardReader.reset_column_information
    SecureRooms::CardReader.find_each { |cr| cr.update_column(:tablet_token, ("A".."Z").to_a.sample(12).join) }
  end

end
