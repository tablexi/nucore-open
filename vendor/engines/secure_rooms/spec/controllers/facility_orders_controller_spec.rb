require "rails_helper"

RSpec.describe FacilityOrdersController do

  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price, facility: facility) }

  let(:account) { create(:nufs_account, :with_account_owner, owner: staff) }
  let!(:in_progress_occupancy) { create(:occupancy, :active, :with_order_detail, secure_room: secure_room, user: staff, account: account) }
  let!(:problem_occupancy) { create(:occupancy, :orphan, :with_order_detail, secure_room: secure_room, user: staff, account: account) }

  let(:staff) { create(:user, :staff, facility: facility) }

  before { sign_in staff }
  describe "index" do
    before { get :index, facility_id: facility }

    it "does not include te occupancies" do
      expect(response).to be_success
      expect(assigns(:order_details)).to eq([])
    end
  end
end
