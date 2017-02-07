require "rails_helper"

RSpec.describe OrderAssignmentMailer do
  let(:email) { ActionMailer::Base.deliveries.last }

  describe ".notify_assigned_user" do
    let(:assigned_user) { FactoryGirl.build(:user) }
    let(:facility) { FactoryGirl.build_stubbed(:facility) }
    let(:order) { FactoryGirl.build_stubbed(:order, facility: facility) }
    let(:order_detail) do
      FactoryGirl.build_stubbed(:order_detail,
                                assigned_user: assigned_user,
                                order: order)
    end

    before { described_class.notify_assigned_user(order_detail).deliver_now }

    it "generates an order assignment notification", :aggregate_failures do
      expect(email.to).to eq [assigned_user.email]
      expect(email.subject).to include("Order Assignment Notice")
      expect(email.html_part.to_s).to include(order_detail.to_s)
      expect(email.text_part.to_s).to include(order_detail.to_s)
    end
  end
end
