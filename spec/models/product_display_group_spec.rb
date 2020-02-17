require "rails_helper"

RSpec.describe ProductDisplayGroup do
  let(:facility) { create(:facility) }

  it "has a valid factory" do
    group = build(:product_display_group)
    expect(group).to be_valid
  end

  it { is_expected.to validate_presence_of(:name) }

  it "can have products" do
    group = create(:product_display_group, facility: facility)
    product = create(:item, :without_validation, facility: facility)
    group.products << product
    expect(group.reload.products).to include(product)
  end

  it "leaves the product ungrouped after delete" do
    group = create(:product_display_group, facility: facility)
    product = create(:item, :without_validation, facility: facility)
    group.products << product

    expect { group.destroy }.to change(ProductDisplayGroupProduct, :count).by(-1).and change(Product, :count).by(0)
  end

  it "fails if you try to add a product that is taken by another group" do
    other_group = create(:product_display_group, facility: facility)
    product = create(:item, :without_validation, facility: facility)
    other_group.products << product

    group = create(:product_display_group, facility: facility)
    expect do
      group.update(product_ids: [product.id])
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect(group.associated_errors.map(&:full_messages)).to include("Product #{product.name} is already in a group")

  end

end
