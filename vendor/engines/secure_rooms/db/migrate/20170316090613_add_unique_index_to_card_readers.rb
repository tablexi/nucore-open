class AddUniqueIndexToCardReaders < ActiveRecord::Migration

  def change
    add_index(
      :secure_rooms_card_readers,
      [:card_reader_number, :control_device_number],
      name: "index_identifying_numbers",
      unique: true,
    )
  end

end
