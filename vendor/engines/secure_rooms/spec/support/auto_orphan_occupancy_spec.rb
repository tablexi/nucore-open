require "rails_helper"

RSpec.describe SecureRooms::AutoOrphanOccupancy, :time_travel do
  let(:action) { described_class.new }

  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, facility: facility) }
  let(:card_reader) { create :card_reader, secure_room: secure_room }
  let(:user) { create(:user) }
  let(:policy) { create(:secure_room_price_policy, product: secure_room, usage_rate: 60, price_group: order_detail.account.price_groups.first) }
  let(:account) { create(:setup_account, :with_account_owner, owner: user, facility_id: facility.id) }
  let!(:order) { create(:purchased_order, account: account, product: secure_room, user: account.owner.user) }
  let(:order_detail) { order.order_details.first }

  before do
    ignore_order_detail_account_validations
    secure_room.update(requires_approval: false)
    allow_any_instance_of(SecureRoom).to receive(:can_purchase?).and_return(true)
  end

  describe '#perform' do
    context "with a very long-running occupancy" do
      let(:event) { create :event, :successful, card_reader: card_reader, user: user }
      let!(:occupancy) do
        create(
          :occupancy,
          :active,
          entry_event: event,
          entry_at: 3.days.ago,
          user: account.owner.user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: account,
        )
      end

      it "orphans the occupancy" do
        expect { action.perform }.to change { occupancy.reload.orphan? }.from(false).to(true)
      end

      it "sends the occupancy through the order handler" do
        expect(SecureRooms::AccessHandlers::OrderHandler).to receive(:process).with(occupancy)
        action.perform
      end

      it "sets the order_detail problem status" do
        action.perform
        expect(order_detail.reload.problem).to be true
      end

      it "does not assign pricing" do
        action.perform
        expect(order_detail.reload.price_policy).to be_nil
      end

      it "sets the order detail fulfilled at time" do
        action.perform
        expect(order_detail.reload.fulfilled_at).to eq occupancy.reload.orphaned_at
      end
    end

    context "with a short-term active occupancy" do
      let!(:occupancy) do
        create(
          :occupancy,
          :active,
          user: order_detail.user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: order_detail.account,
        )
      end

      it "does not orphan the occupancy" do
        expect { action.perform }.not_to change { occupancy.reload.orphan? }
      end

      it "does not involve the order handler" do
        expect(SecureRooms::AccessHandlers::OrderHandler).not_to receive(:process)
        action.perform
      end
    end

    context "with an already completed occupancy" do
      let!(:occupancy) do
        create(
          :occupancy,
          :complete,
          user: order_detail.user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: order_detail.account,
        )
      end

      it "does not orphan the occupancy" do
        expect { action.perform }.not_to change { occupancy.reload.orphan? }
      end

      it "does not involve the order handler" do
        expect(SecureRooms::AccessHandlers::OrderHandler).not_to receive(:process)
        action.perform
      end
    end
  end
end
