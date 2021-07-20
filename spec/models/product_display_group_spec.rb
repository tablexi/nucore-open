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

    expect(group.associated_errors.flat_map(&:full_messages)).to include("Product #{product.name} is already in a group")
  end

  it "does not care about the validity of the product" do
    product = create(:item, :without_validation, facility: facility)
    group = build(:product_display_group, facility: facility, products: [product])
    expect(group).to be_valid
  end

  it "does not affect the relay of an instrument" do
    facility = create(:setup_facility)
    instrument = create(:setup_instrument, facility: facility, relay: build(:relay))
    group = create(:product_display_group, facility: facility, products: [instrument])
    expect(instrument.reload.relay).to be_present
  end

  describe "position" do
    it "sets an incrementing default position on create" do
      group1 = create(:product_display_group, facility: facility)
      expect(group1.position).to eq(1)

      group2 = create(:product_display_group, facility: facility)
      expect(group2.position).to eq(2)
    end

    it "does not overwrite the position if you explicitly set it" do
      group = create(:product_display_group, position: 39, facility: facility)
      expect(group.position).to eq(39)
    end
  end

  describe "any_active?" do
    let(:group) { create(:product_display_group, facility: facility) }

    let(:active_product) {  create(:item, :without_validation, facility: facility,  is_archived: false, is_hidden: false) }

    let(:hidden_product) {  create(:item, :without_validation, facility: facility, is_archived: false, is_hidden: true) }

    it "returns true if there's an active product in the group" do
      group.products << active_product
      expect(group.reload.any_active?).to be true
    end

    it "returns false if there are no active products in the group" do
      group.products << hidden_product
      expect(group.reload.any_active?).to be false
    end
  end
end
