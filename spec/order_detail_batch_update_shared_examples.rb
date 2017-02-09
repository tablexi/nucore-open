RSpec.shared_examples_for "it supports order_detail POST #batch_update" do
  context "POST #batch_update" do
    before do
      @method = :post
      @action = :batch_update
    end

    it_should_allow_operators_only :redirect

    context "when batch-assigning facility staff" do
      let(:admin) { FactoryGirl.create(:user, :facility_administrator, facility: facility) }
      let(:assignee) { FactoryGirl.create(:user, :staff, facility: facility) }
      let(:orders) { FactoryGirl.create_list(:purchased_order, 3, product: product) }
      let(:order_details) { orders.flat_map(&:order_details) }

      before do
        @params[:assigned_user_id] = assignee.id.to_s
        @params[:order_detail_ids] = order_details.map(&:id).map(&:to_s)
        sign_in admin
      end

      it "updates assigned_user_id attributes" do
        expect { do_request }
          .to change { order_details.map(&:reload).map(&:assigned_user_id) }
          .from([nil, nil, nil])
          .to(Array.new(3) { assignee.id })
      end

      it "sends the assignee one notification" do
        expect { do_request }
          .to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end
  end
end
