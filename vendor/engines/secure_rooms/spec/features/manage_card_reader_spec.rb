require "rails_helper"

RSpec.describe "Managing CardReaders" do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, facility: facility) }
  let(:admin) { create(:user, :administrator) }
  before { login_as admin }

  it "can create, edit, and destroy a card reader" do
    visit facility_secure_room_card_readers_path(facility, secure_room)
    click_link "Add Card Reader"
    fill_in "card_reader[description]", with: "New Reader Description"
    fill_in "card_reader[card_reader_number]", with: "New Reader Number"
    fill_in "card_reader[control_device_number]", with: "New Device Number"
    click_button "Create Card Reader"

    new_reader = secure_room.card_readers.find_by(
      card_reader_number: "New Reader Number",
      control_device_number: "New Device Number",
    )

    expect(current_path).to eq(facility_secure_room_card_readers_path(facility, secure_room))
    expect(page).to have_content("New Reader Description")
    expect(page).to have_content("New Reader Number")
    expect(page).to have_content("New Device Number")

    within(".product_list") { click_link "Edit" }
    fill_in "card_reader[description]", with: "Edited Reader Description"
    fill_in "card_reader[card_reader_number]", with: "Edited Reader Number"
    fill_in "card_reader[control_device_number]", with: "Edited Device Number"
    click_button "Update Card Reader"

    expect(current_path).to eq(facility_secure_room_card_readers_path(facility, secure_room))
    expect(page).to have_content("Edited Reader Description")
    expect(page).to have_content("Edited Reader Number")
    expect(page).to have_content("Edited Device Number")
    within(".product_list") { click_link "Remove" }

    expect(current_path).to eq(facility_secure_room_card_readers_path(facility, secure_room))
    expect { SecureRooms::CardReader.find(new_reader.id) }.to raise_error ActiveRecord::RecordNotFound
  end
end
