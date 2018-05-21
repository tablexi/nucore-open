require "rails_helper"

RSpec.describe ProductForCart do

  let(:facility) { FactoryBot.create(:facility) }
  let(:facility_account) { facility.facility_accounts.create(FactoryBot.attributes_for(:facility_account)) }
  let(:item) { facility.items.create(FactoryBot.attributes_for(:item, facility_account_id: facility_account.id)) }
  let(:user) { FactoryBot.create(:user) }

  let(:product_for_cart) { ProductForCart.new(item) }

  context "#purchasable_by?" do

    context "when a product does not have any pricing policies" do
      it "returns false" do
        expect(product_for_cart.purchasable_by?(user, user)).to be false
      end

      it "sets error_message explaining that pricing is unavailable" do
        product_for_cart.purchasable_by?(user, user)
        expect(product_for_cart.error_message).to match(/Pricing for this item is currently unavailable/)
      end
    end

    context "when the product is a bundle" do
      let(:bundle) { FactoryBot.create(:bundle, facility_account: facility_account, facility: facility) }
      let(:bundle_product) { BundleProduct.new(bundle: @bundle, product: item, quantity: 1) }

      let(:product_for_cart) { ProductForCart.new(bundle) }

      before(:each) do
        BundleProduct.create(bundle: bundle, product: item, quantity: 1)
      end

      context "and none of its products have pricing policies" do
        it "sets error_message explaining that pricing is unavailable" do
          product_for_cart.purchasable_by?(user, user)
          expect(product_for_cart.error_message).to match(/Pricing for this bundle is currently unavailable/)
        end
      end

      context "and at least one of its products has pricing policies" do
        before(:each) do
          item.item_price_policies.create!(FactoryBot.attributes_for(:item_price_policy, price_group: @nupg))
        end

        it "does not set error_message about unavailable pricing" do
          product_for_cart.purchasable_by?(user, user)
          expect(product_for_cart.error_message).not_to match(/Pricing for this bundle is currently unavailable/)
        end
      end
    end

  end

end
