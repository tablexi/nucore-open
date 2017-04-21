require "rails_helper"

RSpec.describe SecureRooms::AccessHandlers::OrderHandler, type: :service do
  let(:user) { create :user }
  let(:card_reader) { create :card_reader }
  let(:account) { create :account, :with_account_owner, owner: user }

  describe "#process" do
    context "with an orderable occupancy" do
      let(:occupancy) do
        create(:occupancy, :active, user: user, secure_room: card_reader.secure_room, account: account)
      end

      it "creates an order" do
        expect { described_class.process(occupancy) }
          .to change(Order, :count).by(1)
      end

      it "creates an order detail" do
        expect { described_class.process(occupancy) }
          .to change(OrderDetail, :count).by(1)
      end

      describe "the order" do
        subject(:order) { described_class.process(occupancy) }

        it { is_expected.to be_new }

        it "stores the associations from the Occupancy" do
          expect(order.account).to eq account
          expect(order.user).to eq user
          expect(order.facility).to eq card_reader.facility
          expect(order.created_by_user).to eq user
        end
      end

      describe "the order detail" do
        subject(:order_detail) { described_class.process(occupancy).order_details.first }

        it "stores the associations from the Occupancy" do
          expect(order_detail.product).to eq card_reader.secure_room
          expect(order_detail.created_by_user).to eq user
        end
      end
    end

    context "without an occupancy account" do
      let(:occupancy) do
        create(:occupancy, :active, user: user, secure_room: card_reader.secure_room)
      end

      it "skips order creation" do
        expect { described_class.process(occupancy) }
          .to change(Order, :count).by(0)
      end
    end
  end
end
