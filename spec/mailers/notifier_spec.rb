require "rails_helper"

RSpec.describe Notifier do
  let(:email) { ActionMailer::Base.deliveries.last }
  let(:facility) { create(:setup_facility) }
  let(:order) { create(:purchased_order, product: product) }
  let(:product) { create(:setup_instrument, facility: facility) }
  let(:user) { order.user }

  describe ".order_notification" do
    before { Notifier.order_notification(order, recipient).deliver_now }

    let(:recipient) { "orders@example.net" }

    context "when product has a contact email" do
      let(:product) { create(:setup_instrument, facility: facility, contact_email: "test@example.com") }

      it "generates and order notification with product reply to" do
        expect(email.reply_to).to eq [product.contact_email]
      end
    end

    it "generates an order notification", :aggregate_failures do
      expect(email.to).to eq [recipient]
      expect(email.reply_to).to eq [facility.email]
      expect(email.subject).to include("Order Notification")
      expect(email.html_part.to_s).to match(/Ordered By.+#{user.full_name}/m)
      expect(email.text_part.to_s).to include("Ordered By: #{user.full_name}")
      expect(email.html_part.to_s).to match(/Payment Source.+#{order.account}/m)
      expect(email.text_part.to_s).to include("Payment Source: #{order.account}")
      expect(email.html_part.to_s).not_to include("Thank you for your order")
      expect(email.text_part.to_s).not_to include("Thank you for your order")
    end
  end

  describe ".order_receipt" do
    let(:note) { nil }

    before(:each) do
      order.order_details.first.update_attribute(:note, note) if note.present?
      Notifier.order_receipt(order: order, user: user).deliver_now
    end

    it "generates a receipt", :aggregate_failures do
      expect(email.to).to eq [user.email]
      expect(email.reply_to).to eq [facility.email]
      expect(email.subject).to include("Order Receipt")
      expect(email.html_part.to_s).to match(/Ordered By.+#{user.full_name}/m)
      expect(email.text_part.to_s).to include("Ordered By: #{user.full_name}")
      expect(email.html_part.to_s).to match(/Payment Source.+#{order.account}/m)
      expect(email.text_part.to_s).to include("Payment Source: #{order.account}")
      expect(email.html_part.to_s).to include("Thank you for your order")
      expect(email.text_part.to_s).to include("Thank you for your order")
    end

    context "when ordered on behalf of another user" do
      let(:administrator) { create(:user, :administrator) }
      let(:order) { create(:purchased_order, product: product, created_by: administrator.id) }

      it "mentions who placed the order in the receipt", :aggregate_failures do
        expect(email.html_part.to_s)
          .to match(/Ordered By.+#{administrator.full_name}/m)
        expect(email.text_part.to_s)
          .to include("Ordered By: #{administrator.full_name}")
      end

      context "with a note" do
        let(:note) { "*NOTE CONTENT*" }
        it { expect(email.text_part.to_s).to include("*NOTE CONTENT*") }
        it { expect(email.html_part.to_s).to include("*NOTE CONTENT*") }
      end
    end
  end

  describe ".review_orders" do
    let(:accounts) do
      FactoryGirl.create_list(:setup_account, 2, owner: user, facility_id: facility.id)
    end
    let(:account_ids) { accounts.map(&:id) }
    let(:email_html) { email.html_part.to_s.gsub(/&nbsp;/, " ") } # Markdown changes some whitespace to &nbsp;
    let(:email_text) { email.text_part.to_s }

    before(:each) do
      Notifier.review_orders(user_id: user.id,
                             facility_id: facility.id,
                             account_ids: account_ids).deliver_now
    end

    it "generates a review_orders notification", :aggregate_failures do
      expect(email.to).to eq [user.email]
      expect(email.subject).to include("Orders For Review")

      [email_html, email_text].each do |email_content|
        expect(email_content)
          .to include("/transactions/in_review")
          .and include(accounts.first.description)
          .and include(accounts.last.description)
      end
    end
  end
end
