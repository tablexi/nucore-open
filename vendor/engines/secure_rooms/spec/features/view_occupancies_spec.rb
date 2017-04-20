require "rails_helper"

RSpec.describe "Viewing Occupancies" do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, facility: facility) }
  let(:facility_staff) { create(:user, :staff, facility: facility) }
  before { login_as facility_staff }

  context "with no Occupancies" do
    it "shows that the room is vacant" do
      visit facility_secure_room_occupancies_path(facility, secure_room)

      expect(current_path).to eq(facility_secure_room_occupancies_path(facility, secure_room))
      expect(page).to have_content("The room is currently vacant")
    end
  end

  context "with Occupancies" do
    let!(:active_occupancy) { create(:occupancy, :active, secure_room: secure_room) }
    let!(:orphan_occupancy) { create(:occupancy, :orphan, secure_room: secure_room) }
    let!(:complete_occupancy) { create(:occupancy, :complete, secure_room: secure_room) }
    let!(:remote_occupancy) { create(:occupancy, :active) }

    it "can view only the current Occupancies" do
      visit facility_secure_room_occupancies_path(facility, secure_room)

      expect(current_path).to eq(facility_secure_room_occupancies_path(facility, secure_room))
      within(".secure_rooms_occupancy") do
        expect(page).to have_content(active_occupancy.user.username)
        expect(page).to have_content(active_occupancy.entry_at)
        expect(page).not_to have_content(orphan_occupancy.user.username)
        expect(page).not_to have_content(complete_occupancy.user.username)
        expect(page).not_to have_content(remote_occupancy.user.username)
      end

      within(".secure_rooms_problem_occupancy") do
        expect(page).to have_content(orphan_occupancy.user.username)
      end
    end
  end
end
