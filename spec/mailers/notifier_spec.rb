require "rails_helper"

RSpec.describe Notifier do
  describe ".order_receipt" do
    let(:email) { ActionMailer::Base.deliveries.last }
    let(:note) { nil }
    let(:order) { create(:purchased_order, product: product) }
    let(:product) { create(:setup_instrument) }
    let(:user) { order.user }

    before(:each) do
      order.order_details.first.update_attribute(:note, note) if note.present?
      Notifier.order_receipt(order: order, user: user).deliver
    end

    it { expect(email.to).to eq([user.email]) }
    it { expect(email.subject).to include("Order Receipt") }
    it { expect(email.html_part.to_s).to match(/Ordered By.+\n#{user.full_name}/) }
    it { expect(email.text_part.to_s).to include("Ordered By: #{user.full_name}") }

    context "when ordered on behalf of another user" do
      let(:administrator) { create(:user, :administrator) }
      let(:order) { create(:purchased_order, product: product, created_by: administrator.id) }

      it { expect(email.html_part.to_s).to match(/Ordered By.+\n#{administrator.full_name}/) }
      it { expect(email.text_part.to_s).to include("Ordered By: #{administrator.full_name}") }

      context "with a note" do
        let(:note) { "*NOTE CONTENT*" }
        it { expect(email.text_part.to_s).to include("*NOTE CONTENT*") }
        it { expect(email.html_part.to_s).to include("*NOTE CONTENT*") }
      end
    end
  end
end
