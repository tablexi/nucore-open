require "rails_helper"

RSpec.describe "Purchasing a reservation" do
  fixtures :all

  let(:facility) { facilities(:facility) }
  let(:instrument) { products(:reservation_only_instrument) }
  let(:user) { users(:normal_user) }

  before do
    login_as user
    visit root_path
    click_link facility.name
    click_link instrument.name
    select user.accounts.first.description, from: "Payment Source"
    click_button "Create"
  end

  it "is on the My Reservations page" do
    expect(page).to have_content "My Reservations"
  end
end
