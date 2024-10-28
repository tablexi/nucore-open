RSpec.shared_examples "with hidden price groups" do |item_type|
  let!(:price_group_to_hide) { create(:price_group, facility: facility) }

  it "hides price policies related to that price group" do
    visit send("facility_#{item_type}s_path", facility, item)
    click_link item.name
    click_link "Pricing"
    click_link "Add Pricing Rules"

    expect(page).to have_content(price_group_to_hide.name)

    if item_type == "instrument"
      fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
      fill_in "price_policy_#{base_price_group.id}[minimum_cost]", with: "120"
      fill_in "price_policy_#{base_price_group.id}[cancellation_cost]", with: "15"

      fill_in "price_policy_#{external_price_group.id}[usage_rate]", with: "120.11"
      fill_in "price_policy_#{external_price_group.id}[minimum_cost]", with: "122"
      fill_in "price_policy_#{external_price_group.id}[cancellation_cost]", with: "31"

      check "price_policy_#{price_group_to_hide.id}[can_purchase]"
      fill_in "price_policy_#{price_group_to_hide.id}[usage_subsidy]", with: "40"
    else
      fill_in "price_policy_#{base_price_group.id}[unit_cost]", with: "100.00"
      fill_in "price_policy_#{cancer_center.id}[unit_subsidy]", with: "25.25"
      fill_in "price_policy_#{external_price_group.id}[unit_cost]", with: "40"
      fill_in "price_policy_#{price_group_to_hide.id}[unit_subsidy]", with: "40"
    end

    fill_in "note", with: "This is my note"

    click_button "Add Pricing Rules"
    
    expect(page).to have_content(base_price_group.name)
    expect(page).to have_content(price_group_to_hide.name)

    visit edit_facility_price_group_path(facility, price_group_to_hide)

    check "Is Hidden?"

    click_button "Update"

    visit send("facility_#{item_type}s_path", facility, item)

    click_link item.name
    click_link "Pricing"

    expect(page).to have_content(base_price_group.name)
    expect(page).not_to have_content(price_group_to_hide.name)

    click_link "Add Pricing Rules"

    expect(page).to have_content(base_price_group.name)
    expect(page).not_to have_content(price_group_to_hide.name)
  end
end