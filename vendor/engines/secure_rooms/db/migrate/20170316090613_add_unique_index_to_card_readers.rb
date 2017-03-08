class AddUniqueIndexToCardReaders < ActiveRecord::Migration

  def change
    add_index(
      :secure_rooms_card_readers,
      [:product_id, :card_reader_number, :control_device_number],
      name: "index_secure_rooms_card_readers_on_product_id_and_both_numbers",
      unique: true,
    )
  end

end
