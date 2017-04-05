class AddTableTokenToCardReaders < ActiveRecord::Migration

  class SecureRooms::CardReader < ActiveRecord::Base
  end

  def change
    add_column :secure_rooms_card_readers, :tablet_token, :string
    SecureRooms::CardReader.reset_column_information
    SecureRooms::CardReader.find_each { |cr| cr.update_column(:tablet_token, ("A".."Z").to_a.sample(12).join) }
  end

end
