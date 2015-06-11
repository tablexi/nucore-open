require "spec_helper"

describe ProductUserObserver do
  describe "#after_create" do
    let(:product) { create(:setup_instrument, requires_approval: true) }
    let(:product_user) do
      ProductUser.new(user: user, product: product, approved_by: user.id)
    end
    let(:user) { create(:user) }

    context "when a corresponding training request exists" do
      let!(:training_request) do
        create(:training_request, user: user, product: product)
      end

      it "records the training request timestamp" do
        requested_at = training_request.reload.created_at
        expect { product_user.save! }
          .to change(product_user, :requested_at).from(nil).to(requested_at)
      end

      it "destroys the training request" do
        expect { product_user.save! }.to change(TrainingRequest, :count).by(-1)
      end
    end

    context "when a training request does not exist" do
      it "records no training request timestamp" do
        expect { product_user.save! }
          .not_to change(product_user, :requested_at).from(nil)
      end
    end
  end
end
