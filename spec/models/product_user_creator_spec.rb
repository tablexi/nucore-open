require "spec_helper"

describe ProductUserCreator do
  subject do
    -> { ProductUserCreator.create(user: user, product: product, approver: approver) }
  end
  let(:user) { create(:user) }
  let(:product) { create(:instrument_requiring_approval) }
  let(:approver) { create(:user, :administrator) }

  describe ".create" do
    let(:product_user) { subject.call }

    it "creates a ProductUser" do
      expect { subject.call }.to change(ProductUser, :count).by(1)
    end

    context "when there is a pending training request" do
      let!(:training_request) do
        create(:training_request, user: user, product: product)
      end

      it "sets the requested_at time" do
        training_request_created_at = training_request.reload.created_at
        expect(product_user.requested_at).to eq(training_request_created_at)
      end

      it "destroys the training request" do
        expect { subject.call }.to change(TrainingRequest, :count).by(-1)
      end
    end

    context "when there are no pending training requests" do
      it "does not set the requested_at time" do
        expect(product_user.requested_at).to be_blank
      end

      it "does not destroy training requests" do
        expect { subject.call }.not_to change(TrainingRequest, :count)
      end
    end
  end
end
