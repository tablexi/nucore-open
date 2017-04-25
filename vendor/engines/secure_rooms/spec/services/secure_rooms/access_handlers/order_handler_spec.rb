require "rails_helper"

RSpec.describe SecureRooms::AccessHandlers::OrderHandler, type: :service do
  let(:user) { create :user }
  let(:secure_room) { create :secure_room }
  let(:card_reader) { create :card_reader, secure_room: secure_room }
  let(:account) { create :account, :with_account_owner, owner: user }

  describe "#process" do
    context "with an orderable occupancy" do
      before do
        secure_room.update(requires_approval: false)
        allow_any_instance_of(Product).to receive(:can_purchase_order_detail?).and_return(true)
      end

      let(:occupancy) do
        create(:occupancy, :active, user: user, secure_room: secure_room, account: account)
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

        it { is_expected.to be_purchased }

        it "sets ordered_at" do
          expect(order.ordered_at).to be_present
        end

        it "stores the associations from the Occupancy" do
          expect(order.account).to eq account
          expect(order.user).to eq user
          expect(order.facility).to eq card_reader.facility
          expect(order.created_by_user).to eq user
        end
      end

      describe "the order detail" do
        subject(:order_detail) { described_class.process(occupancy).order_details.first }

        it { is_expected.to be_new }

        it "sets order_status" do
          expect(order_detail.order_status).to eq OrderStatus.new_status
        end

        it "stores the associations from the Occupancy" do
          expect(order_detail.product).to eq card_reader.secure_room
          expect(order_detail.occupancy).to eq occupancy
          expect(order_detail.created_by_user).to eq user
        end
      end

      # TODO: Clean me up pls
      context "when completing the occupancy" do
        let(:occupancy) do
          create(
            :occupancy,
            :complete,
            user: user,
            secure_room: secure_room,
            account: account,
          )
        end

        it "sets ordered_at" do
          order = Order.create!(
            account: occupancy.account,
            user: occupancy.user,
            facility: occupancy.facility,
            created_by_user: occupancy.user,
          )

          order_detail = order.order_details.create!(
            account: occupancy.account,
            product: occupancy.secure_room,
            occupancy: occupancy,
            created_by_user: occupancy.user,
            quantity: 1,
          )

          order.validate_order!
          order.purchase!

          order_detail = described_class.process(occupancy).order_details.first

          expect(order_detail).to be_complete
          expect(order_detail.fulfilled_at).to be_present

          # TODO: expect price_policy to be_present
          # TODO: expect price to be_present
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
