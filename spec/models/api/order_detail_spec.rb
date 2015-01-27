require "spec_helper"

describe Api::OrderDetail do
  subject { Api::OrderDetail.new(order_detail) }

  let(:expected_hash) {{ account: account_hash, ordered_for: ordered_for_hash }}

  let(:order) { double(Order, user: ordered_for) }
  let(:order_detail) { double(OrderDetail, account: account, order: order) }
  let(:ordered_for) { build(:user, id: 2) }
  let(:ordered_for_hash) {{
    id: ordered_for.id,
    name: ordered_for.name,
    username: ordered_for.username,
    email: ordered_for.email,
  }}

  describe "#to_h" do
    context "when the order_detail has an account" do
      let(:account) { double(Account, id: 1, owner: account_user) }
      let(:account_owner) { build(:user, id: 1) }
      let(:account_user) { double(AccountUser, user: account_owner) }
      let(:account_hash) {{
        id: account.id,
        owner: {
          id: account_owner.id,
          name: account_owner.name,
          username: account_owner.username,
          email: account_owner.email,
        }
      }}

      it "generates the expected hash" do
        expect(subject.to_h).to eq(expected_hash)
      end
    end

    context "when the order_detail has no account" do
      let(:account) { nil }
      let(:account_hash) { nil }

      it "generates the expected hash" do
        expect(subject.to_h).to eq(expected_hash)
      end
    end
  end
end
