require "rails_helper"

RSpec.describe SecureRooms::AccessHandlers::OccupancyHandler, type: :service do
  let(:event) { create :event, card_reader: card_reader }

  shared_examples_for "a new occupancy" do
    it "creates a new Occupancy" do
      expect { described_class.process(event) }
        .to change(SecureRooms::Occupancy, :count).by(1)
    end
  end

  shared_examples_for "the exit occupancy" do
    it "sets the exit_event and timestamp" do
      expect(occupancy.exit_event).to eq event
      expect(occupancy.exit_at).to be_present
    end
  end

  shared_examples_for "the entry occupancy" do
    it "sets the entry_event and timestamp" do
      expect(occupancy.entry_event).to eq event
      expect(occupancy.entry_at).to be_present
    end
  end

  shared_examples_for "an orphaned occupancy" do
    it "sets orphan status" do
      expect(occupancy).to be_orphan
    end
  end

  shared_examples_for "a problem order" do
    it "results in a problem order" do
      expect(occupancy.order_detail).to be_complete
      expect(occupancy.order_detail).to be_problem
    end
  end

  describe "#process" do
    context "current_occupant?" do
      let(:account) { create :account, :with_account_owner, owner: event.user }
      let!(:existing_occupancy) do
        create(
          :occupancy,
          :active,
          entry_event: event,
          secure_room: card_reader.secure_room,
          user: event.user,
          account: account,
        )
      end

      context "exiting" do
        let(:card_reader) { create :card_reader, ingress: false }

        it "updates existing Occupancy" do
          expect { described_class.process(event) }
            .not_to change(SecureRooms::Occupancy, :count)
        end

        it_should_behave_like "the exit occupancy" do
          subject(:occupancy) { described_class.process(event) }
        end
      end

      context "entering" do
        let(:card_reader) { create :card_reader, ingress: true }

        # orders need to be "purchased" but we don't care about the details
        before { allow_any_instance_of(OrderDetail).to receive(:valid_for_purchase?).and_return(true) }

        describe "the new occupancy" do
          subject(:occupancy) { described_class.process(event) }

          it_should_behave_like "a new occupancy"
          it_should_behave_like "the entry occupancy"
        end

        describe "the existing occupancy" do
          subject(:occupancy) { existing_occupancy.reload }
          before { described_class.process(event) }

          it_should_behave_like "an orphaned occupancy"
          it_should_behave_like "a problem order"
        end
      end
    end

    context "new_occupant" do
      context "entering" do
        let(:card_reader) { create :card_reader, ingress: true }

        describe "the new occupancy" do
          subject(:occupancy) { described_class.process(event) }

          it_should_behave_like "a new occupancy"
          it_should_behave_like "the entry occupancy"
        end
      end

      context "exiting" do
        let(:card_reader) { create :card_reader, ingress: false }

        describe "the new occupancy" do
          subject(:occupancy) { described_class.process(event) }

          it_should_behave_like "a new occupancy"
          it_should_behave_like "the exit occupancy"
          it_should_behave_like "an orphaned occupancy"
        end
      end
    end
  end
end
