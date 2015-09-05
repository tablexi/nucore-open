require "rails_helper"

RSpec.describe ProductUser do
  let(:facility) { create(:facility) }
  let(:facility_account) do
    facility.facility_accounts.create(attributes_for(:facility_account))
  end
  let(:item) { facility.items.create(item_attributes) }
  let(:item_attributes) do
    attributes_for(
      :item,
      facility_account_id: facility_account.id,
      requires_approval: true,
    )
  end
  let(:user) { create(:user) }

  context "when creating with valid attributes" do
    subject(:product_user) do
      ProductUser.create(product: item, user: user, approved_by: user.id)
    end

    it "is valid" do
      expect(product_user).to be_valid
      expect(product_user.errors).to be_empty
    end

    it "assigns approved_at" do
      expect(product_user.approved_at).to be_present
    end
  end

  context "when approved_by is missing" do
    subject(:product_user) { ProductUser.new(approved_by: nil) }

    it "is invalid" do
      expect(product_user).to_not be_valid
      expect(product_user.errors[:approved_by]).to be_present
    end
  end

  context "when product_id is missing" do
    subject(:product_user) { ProductUser.new(product_id: nil) }

    it "is invalid" do
      expect(product_user).to_not be_valid
      expect(product_user.errors[:product_id]).to be_present
    end
  end

  context "when user_id is missing" do
    subject(:product_user) { ProductUser.new(user_id: nil) }

    it "is invalid" do
      expect(product_user).to_not be_valid
      expect(product_user.errors[:user_id]).to be_present
    end
  end
end
