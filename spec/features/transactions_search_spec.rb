require "rails_helper"

RSpec.describe "Transactions Index Search" do

  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:item2) { create(:setup_item, facility: facility) }
  let(:user) { create(:user) }
  let(:accounts) { create_list(:setup_account, 2, owner: user) }
  let!(:orders) do
    accounts.map do |account|
      [create(:purchased_order, product: item, account: account),
       create(:purchased_order, product: item2, account: account)]
    end.flatten
  end

  let!(:completed_orders) do
    accounts.map do |account|
      [create(:complete_order, product: item, account: account),
       create(:complete_order, product: item2, account: account)]
    end.flatten
  end

  it "can do a basic search" do
    login_as user
    visit transactions_path

    select accounts.first.description, from: "Payment Sources"
    click_button "Filter"
    save_and_open_page
    expect(page).to have_css('td', text: accounts.first.description, count: 2)
    expect(page).not_to have_css('td', text: accounts.last.description, count: 2)

  end

end
