require "rails_helper"

RSpec.describe "Creating a SecureRoom" do
  let(:facility) { create(:setup_facility) }
  let(:admin) { create(:user, :administrator) }
  before { login_as admin }

  it "can create and edit a secure room" do
    visit facility_products_path(facility)
    click_link "Secure Rooms"
    click_link "Add Secure Room"
    fill_in "secure_room[name]", with: "New Room"
    fill_in "URL Name", with: "new-room"
    click_button "Create"

    expect(current_path).to eq(manage_facility_secure_room_path(facility, SecureRoom.last))

    visit facility_secure_rooms_path(facility)
    click_link "New Room"
    click_link "Edit"

    fill_in "secure_room[description]", with: "Some description"
    click_button "Save"
    expect(SecureRoom.last.description).to eq("Some description")
  end
end
