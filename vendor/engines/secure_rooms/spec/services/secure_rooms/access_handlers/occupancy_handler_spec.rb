require "rails_helper"

RSpec.describe SecureRooms::AccessHandlers::OccupancyHandler, type: :service do
  let(:event) { create :event, card_reader: card_reader }

  describe "#process" do
    context "current_occupant? && exiting?" do
      let(:card_reader) { create :card_reader, ingress: false }

      let!(:existing_occupancy) do
        create(
          :occupancy,
          entry_event: event,
          secure_room: card_reader.secure_room,
          user: event.user,
        )
      end

      it "updates existing Occupancy" do
        expect { described_class.process(event) }
          .not_to change(SecureRooms::Occupancy, :count)
      end

      describe "resulting Occupancy" do
        subject(:occupancy) { described_class.process(event) }

        it "stores the secure_room and user" do
          expect(occupancy.secure_room).to eq card_reader.secure_room
          expect(occupancy.user).to eq event.user
        end

        it "sets the exit_event" do
          expect(occupancy.exit_event).to eq event
        end
      end
    end

    context "new_occupant? && entering?" do
      let(:card_reader) { create :card_reader, ingress: true }

      it "creates an Occupancy" do
        expect { described_class.process(event) }
          .to change(SecureRooms::Occupancy, :count).by(1)
      end

      describe "resulting Occupancy" do
        subject(:occupancy) { described_class.process(event) }

        it "sets the entry_event" do
          expect(occupancy.entry_event).to eq event
        end
      end
    end
  end
end
