require "rails_helper"

RSpec.describe "Placing an item order" do
  let!(:product) { FactoryBot.create(:setup_item) }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { product.facility }
  let!(:price_policy) do
    FactoryBot.create(:item_price_policy,
                      price_group: PriceGroup.base, product: product,
                      unit_cost: 33.25)
  end
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end
  let(:user) { FactoryBot.create(:user) }

  before do
    login_as user
  end

  describe "adding an item to the cart" do
    def add_to_cart
      visit "/"
      click_link facility.name
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
    end

    it "can place an order", :aggregate_failures do
      add_to_cart
      click_button "Purchase"
      expect(page).to have_content "Order Receipt"
      expect(page).to have_content "Ordered By\n#{user.full_name}"
      expect(page).to have_content "$33.25"
    end

    it "can place an order with a note if the feature is enabled for the product" do
      product.update_attributes!(user_notes_field_mode: "optional")
      add_to_cart
      fill_in "Note", with: "This is a note"
      click_button "Purchase"
      expect(page).to have_content "Order Receipt"
      expect(page).to have_content "This is a note"
    end

    it "cannot place an order while missing the note if it is required, and has a custom label" do
      product.update!(
        user_notes_field_mode: "required",
        user_notes_label: "Show me what you got",
      )
      add_to_cart
      click_button "Purchase"
      expect(page).to have_content("may not be blank")

      fill_in "Show me what you got", with: "A note"
      click_button "Purchase"
      expect(page).to have_content "Order Receipt"
    end
  end
end
