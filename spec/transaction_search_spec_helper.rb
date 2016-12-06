require "transaction_search_shared_examples"

def it_should_support_searching(date_range_field = :fulfilled_at)
  context "searching" do
    let(:action) { @action }
    let(:params) { @params }

    before :each do
      sign_in @user
      get action, params
    end

    it_behaves_like TransactionSearch, date_range_field
  end
end
