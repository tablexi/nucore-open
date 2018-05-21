require "rails_helper"

RSpec.describe ProductForCart do

  let(:facility) { FactoryBot.create(:facility) }
  let(:facility_account) { facility.facility_accounts.create(FactoryBot.attributes_for(:facility_account)) }
  let(:item) do
    facility.items.create(FactoryBot.attributes_for(:item, facility_account_id: facility_account.id)).tap do |item|
      item.item_price_policies.create(FactoryBot.attributes_for(:item_price_policy, price_group: @nupg))
    end
  end
  let(:user) { FactoryBot.create(:user) }

  let(:product_for_cart) { ProductForCart.new(item) }

  describe "#purchasable_by?" do

    context "when a product is not available for purchase" do
      before(:each) { allow(item).to receive(:available_for_purchase?).and_return(false) }

      it("returns false") { expect(product_for_cart.purchasable_by?(user, user)).to be false }

      it "sets error_message explaining that the product can’t be purchased online" do
        product_for_cart.purchasable_by?(user, user)
        expect(product_for_cart.error_message).to match(/unavailable for purchase online/)
      end
    end

    context "when a product does not have any price policies" do
      before(:each) { item.price_policies.delete_all }

      context "and it is not a bundle" do
        it("returns false") { expect(product_for_cart.purchasable_by?(user, user)).to be false }

        it "sets error_message explaining that pricing is unavailable" do
          product_for_cart.purchasable_by?(user, user)
          expect(product_for_cart.error_message).to match(/Pricing for this item is currently unavailable/)
        end
      end

      context "and it is a bundle" do
        let(:bundle) { FactoryBot.create(:bundle, facility_account: facility_account, facility: facility) }
        let(:bundle_product) { BundleProduct.new(bundle: @bundle, product: item, quantity: 1) }
        let(:product_for_cart) { ProductForCart.new(bundle) }

        before(:each) { BundleProduct.create(bundle: bundle, product: item, quantity: 1) }

        context "and none of its products have pricing policies" do
          before(:each) { item.price_policies.delete_all }

          it "sets error_message explaining that pricing is unavailable" do
            product_for_cart.purchasable_by?(user, user)
            expect(product_for_cart.error_message).to match(/Pricing for this bundle is currently unavailable/)
          end
        end

        context "and at least one of its products has pricing policies" do
          before(:each) do
            item.item_price_policies.create(FactoryBot.attributes_for(:item_price_policy, price_group: @nupg))
          end

          it "does not set error_message about unavailable pricing" do
            product_for_cart.purchasable_by?(user, user)
            expect(product_for_cart.error_message).not_to match(/Pricing for this bundle is currently unavailable/)
          end
        end
      end
    end

    context "when a product can’t be used by the acting user and can’t be overridden by the session user" do
      before(:each) do
        allow(item).to receive(:can_be_used_by?).and_return(false)
        allow(user).to receive(:can_override_restrictions?).and_return(false)
        allow(SettingsHelper).to receive(:feature_on?).and_return(true)
      end

      context "and training requests are turned on" do
        before(:each) { allow(SettingsHelper).to receive(:feature_on?).with(:training_requests).and_return(true) }

        context "and the user has already submitted a training request" do
          before(:each) { allow(TrainingRequest).to receive(:submitted?).and_return(true) }

          it "sets error_message explaining that the user has already requested access" do
            product_for_cart.purchasable_by?(user, user)
            expect(product_for_cart.error_message).to match(/You have requested/)
          end

          it "sets error_path to the facility page" do
            product_for_cart.purchasable_by?(user, user)
            expect(product_for_cart.error_path).to eq Rails.application.routes.url_helpers.facility_path(item.facility)
          end
        end

        context "and the user has not submitted a training request yet" do
          before(:each) { allow(TrainingRequest).to receive(:submitted?).and_return(false) }

          it "sets error_path to the page for making a training request" do
            product_for_cart.purchasable_by?(user, user)
            expect(product_for_cart.error_path).to eq Rails.application.routes.url_helpers.new_facility_product_training_request_path(item.facility, item)
          end
        end
      end

      context "and training requests are turned off" do
        before(:each) { allow(SettingsHelper).to receive(:feature_on?).with(:training_requests).and_return(false) }

        it "sets error_message explaining that the product requires approval" do
          product_for_cart.purchasable_by?(user, user)
          expect(product_for_cart.error_message).to match(/requires approval to purchase/)
        end
      end
    end

    context "when the acting user does not belong to any price groups that can purchase the product" do
      before(:each) { allow(item).to receive(:can_purchase?).and_return(false) }

      it "sets error_message explaining why they can’t purchase the product" do
        product_for_cart.purchasable_by?(user, user)
        expect(product_for_cart.error_message).to match(/You are not in a price group that may/)
      end
    end

    context "when the acting user does not have any accounts that can purchase the product" do
      before(:each) { allow(user).to receive(:accounts_for_product).and_return([]) }

      it "sets error_message explaining that we could not find a valid payment source" do
        product_for_cart.purchasable_by?(user, user)
        expect(product_for_cart.error_message).to match(/could not find a valid payment source/)
      end
    end

  end

end
