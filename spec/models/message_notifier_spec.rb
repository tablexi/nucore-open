require "spec_helper"

describe MessageNotifier do
  subject { MessageNotifier.new(user, ability, facility) }
  let(:ability) { :stub_ability }
  let(:facility) { order.facility }
  let(:order) { create(:purchased_order, product: product) }
  let(:order_detail) { order.order_details.first }
  let(:product) { create(:instrument_requiring_approval) }
  let(:user) { create(:user) }

  let(:disputed_orders_visible?) { false }
  let(:manage_training_requests?) { false }
  let(:notifications_visible?) { false }
  let(:show_problem_orders?) { false }
  let(:show_problem_reservations?) { false }

  before(:each) do
    subject.stub(:disputed_orders_visible?).and_return(disputed_orders_visible?)
    subject.stub(:manage_training_requests?).and_return(manage_training_requests?)
    subject.stub(:notifications_visible?).and_return(notifications_visible?)
    subject.stub(:show_problem_orders?).and_return(show_problem_orders?)
    subject.stub(:show_problem_reservations?).and_return(show_problem_reservations?)
  end

  def create_merge_notification
    merge_to_order = order.dup
    merge_to_order.save!
    order.update_attribute(:merge_with_order_id, merge_to_order.id)
    MergeNotification.create_for!(user, order_detail.reload)
  end

  def set_problem_order
    order_detail.update_attribute(:state, :complete)
    order_detail.set_problem_order
  end

  shared_examples_for "there are no messages" do
    it "has no messages of any kind" do
      expect(subject).not_to be_messages
      expect(subject).not_to be_notifications
      expect(subject).not_to be_problem_order_details
      expect(subject).not_to be_problem_reservation_order_details
      expect(subject.message_count).to eq(0)
      expect(subject.notifications.count).to eq(0)
      expect(subject.problem_order_details.count).to eq(0)
      expect(subject.problem_reservation_order_details.count).to eq(0)
      expect(subject.training_requests.count).to eq(0)
    end
  end

  shared_examples_for "there is one overall message" do
    it "has one message" do
      expect(subject).to be_messages
      expect(subject.message_count).to eq(1)
    end
  end

  context "when no active notifications, training requests, disputed or problem orders exist" do
    it_behaves_like "there are no messages"
  end

  context "when an active notification exists" do
    before { create_merge_notification }

    context "and the user may view notifications" do
      let(:notifications_visible?) { true }

      it_behaves_like "there is one overall message"

      it "has one notification" do
        expect(subject).to be_notifications
        expect(subject.notifications.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there is one overall message"

        it "has one notification" do
          expect(subject).to be_notifications
          expect(subject.notifications.count).to eq(1)
        end
      end
    end

    context "and the user may not view notifications" do
      let(:notifications_visible?) { false }

      it_behaves_like "there are no messages"
    end
  end

  context "when a disputed order detail exists" do
    before { order_detail.update_attribute(:dispute_at, 1.day.ago) }

    context "and the user can access disputed order details" do
      let(:disputed_orders_visible?) { true }

      it_behaves_like "there is one overall message"

      it "has one disputed order detail message" do
        expect(subject).to be_order_details_in_dispute
        expect(subject.order_details_in_dispute.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there are no messages"
      end
    end

    context "and the user cannot access problem orders" do
      let(:disputed_orders_visible?) { false }

      it_behaves_like "there are no messages"
    end
  end

  context "when a problem order detail exists" do
    let(:product) { create(:setup_item) }

    before(:each) { set_problem_order }

    context "and the user can access problem orders" do
      let(:show_problem_orders?) { true }

      it_behaves_like "there is one overall message"

      it "has one problem order detail message" do
        expect(subject).to be_problem_order_details
        expect(subject.problem_order_details.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there are no messages"
      end
    end

    context "and the user cannot access problem orders" do
      let(:show_problem_orders?) { false }

      it_behaves_like "there are no messages"
    end
  end

  context "when a problem reservation order detail exists" do
    before(:each) { set_problem_order }

    context "and the user can access problem reservations" do
      let(:show_problem_reservations?) { true }

      it_behaves_like "there is one overall message"

      it "has one problem reservation order detail message" do
        expect(subject).to be_problem_reservation_order_details
        expect(subject.problem_reservation_order_details.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there are no messages"
      end
    end

    context "and the user cannot access problem reservations" do
      let(:show_problem_reservations?) { false }

      it_behaves_like "there are no messages"
    end
  end

  context "when a training request exists" do
    before { create(:training_request, product: product) }

    context "and the user can manage training requests" do
      let(:manage_training_requests?) { true }

      it_behaves_like "there is one overall message"

      it "has one training request message" do
        expect(subject).to be_training_requests
        expect(subject.training_requests.count).to eq(1)
      end

      context "when not scoped to a facility" do
        subject { MessageNotifier.new(user, ability, nil) }

        it_behaves_like "there are no messages"
      end
    end

    context "and the user cannot manage training requests" do
      let(:manage_training_requests?) { false }

      it_behaves_like "there are no messages"
    end
  end
end
