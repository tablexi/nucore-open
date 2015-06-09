require "spec_helper"

describe TrainingRequest do
  let(:user) { create(:user) }

  describe "#new" do
    subject { build(:training_request, user: user, product: product) }

    context "when the product has restricted access" do
      let(:product) { create(:instrument_requiring_approval) }

      context "when the user is already on the list" do
        let!(:previous_training_request) do
          create(:training_request, user: user, product: product)
        end

        it "does not add the user to the list" do
          expect { subject.save }.not_to change(TrainingRequest, :count)
        end

        context "when the user has been removed from the list" do
          before { previous_training_request.destroy }

          it "adds the user to the list" do
            expect { subject.save }.to change(TrainingRequest, :count).by(1)
          end
        end
      end

      context "when the user is not on the list" do
        it "adds the user to the list" do
          expect { subject.save }.to change(TrainingRequest, :count).by(1)
        end
      end
    end

    context "when the product has no restricted access" do
      let(:product) { create(:setup_instrument) }

      it "does not add the user to the list" do
        expect { subject.save }.not_to change(TrainingRequest, :count)
      end
    end
  end
end
