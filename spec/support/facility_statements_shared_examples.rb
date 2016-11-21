RSpec.shared_examples "it sets up order_detail and creates statements" do
  it "sets up order_detail and creates statements" do
    expect(@order_detail1.reload.reviewed_at).to be < Time.zone.now
    expect(@order_detail1.statement).to be_nil
    expect(@order_detail1.price_policy).not_to be_nil
    expect(@order_detail1.account.type).to eq(@account_type)
    expect(@order_detail1.dispute_at).to be_nil

    grant_and_sign_in(@user)
    do_request
    expect(flash[:error]).to be_nil
    expect(response).to redirect_to action: :new
  end
end
