require "rails_helper"

RSpec.describe "Viewing Occupancies" do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, facility: facility) }
  let(:facility_staff) { create(:user, :staff, facility: facility) }
  before { login_as facility_staff }

  context "with no in-progress occupancies" do
    it "shows no occupancies" do
      visit facility_occupancies_path(facility)

      expect(current_path).to eq(facility_occupancies_path(facility))
      expect(page).to have_content("There are no \"In Process\" occupancies.")
    end
  end

  context "with occupancy" do
    let(:account) { create :account, :with_account_owner, owner: facility_staff }

    before do
      # Allow purchase of order
      # TODO: Update when new factories are merged in
      allow_any_instance_of(Order).to receive(:cart_valid?).and_return(true)
      allow_any_instance_of(OrderDetail).to receive(:account_usable_by_order_owner?).and_return(true)
    end

    context "with an active occupancy" do
      let!(:active_occupancy) { create(:occupancy, :active, secure_room: secure_room, account: account) }

      before do
        SecureRooms::AccessHandlers::OrderHandler.process(active_occupancy)
      end

      it "shows the order details" do
        visit facility_occupancies_path(facility)

        expect(current_path).to eq(facility_occupancies_path(facility))
        within(".occupancies") do
          expect(page).to have_content(active_occupancy.order_detail.id)
          expect(page).to have_content(active_occupancy.user.full_name)
          expect(page).to have_content(I18n.l(active_occupancy.entry_at, format: :usa))
          expect(page).to have_content(active_occupancy.secure_room.name)
        end
      end
    end

    context "with a problem occupancy" do
      let!(:problem_occupancy) { create(:occupancy, :orphan, secure_room: secure_room, account: account) }
      let(:account) { create :account, :with_account_owner, owner: facility_staff }

      before do
        SecureRooms::AccessHandlers::OrderHandler.process(problem_occupancy)
      end

      it "shows the order details" do
        visit show_problems_facility_occupancies_path(facility)

        expect(current_path).to eq(show_problems_facility_occupancies_path(facility))
        # TODO: Update specs after page is updated
        expect(page).to have_content(problem_occupancy.order_detail.id)
        expect(page).to have_content(problem_occupancy.user.full_name)
        expect(page).to have_content(problem_occupancy.secure_room.name)
      end
    end
  end
end
