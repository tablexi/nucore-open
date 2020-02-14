require "rails_helper"

RSpec.describe ProductDisplayGroup do

  it "has a valid factory" do
    group = build(:product_display_group)
    expect(group).to be_valid
  end

  it { is_expected.to validate_presence_of(:name) }

  it "can have products" do
    facility = create(:facility)
    group = create(:product_display_group, facility: facility)
    product = create(:item, :without_validation, facility: facility)
    group.products << product
    expect(group.reload.products).to include(product)
  end

  it "leaves the product ungrouped after delete" do
    facility = create(:facility)
    group = create(:product_display_group, facility: facility)
    product = create(:item, :without_validation, facility: facility)
    group.products << product

    expect { group.destroy }.to change(ProductDisplayGroupProduct, :count).by(-1).and change(Product, :count).by(0)
  end

end
