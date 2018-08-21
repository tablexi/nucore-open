# frozen_string_literal: true

RSpec.shared_examples "it does not complete order" do
  it "leaves fulfilled_at nil" do
    expect(order_detail.fulfilled_at).to be_nil
  end

  it "leaves price policy nil" do
    expect(order_detail.price_policy).to be_nil
  end

  it "is not a problem order" do
    expect(order_detail).to_not be_problem
  end

  it "is not complete" do
    expect(order_detail.state).to_not eq("complete")
  end

  it "does not set actual end at" do
    expect(order_detail.reservation.actual_end_at).to be_nil
  end

  it "leaves state as new" do
    expect(order_detail.state).to eq("new")
  end
end
