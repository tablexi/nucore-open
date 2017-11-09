require "rails_helper"

RSpec.describe "Purchasing a reservation" do

  let!(:instrument) { FactoryGirl.create(:setup_instrument, user_notes_field_mode: "optional") }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryGirl.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:account_price_group_member) do
    FactoryGirl.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  before do
    login_as user
    visit root_path
    click_link facility.name
  end

  describe "selecting the default time" do
    before do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
      fill_in "Note", with: "A note about my reservation"
      click_button "Create"
    end

    it "is on the My Reservations page" do
      expect(page).to have_content "My Reservations"
      expect(page).to have_content "Note: A note about my reservation"
    end
  end

  describe "attempting to order in the past", :time_travel do
    let(:now) { Time.zone.local(2016, 8, 20, 11, 0) }

    before do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
      select "10", from: "reservation[reserve_start_hour]"
      select "10", from: "reservation[reserve_end_hour]"
      click_button "Create"
    end

    it "has an error" do
      expect(page).to have_content "must start at a future time"
    end
  end

  describe "trying to order with a required note" do
    before do
      instrument.update!(
        user_notes_field_mode: "required",
        user_notes_label: "Show me what you got",
      )
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
    end

    it "does not create the reservation without a note" do
      click_button "Create"
      expect(page).to have_content "Note may not be blank"

      fill_in "Show me what you got", with: "This is my note."
      click_button "Create"

      expect(page).to have_content("My Reservations")
    end

  end

  describe "ordering over an administrative hold" do

    describe "when you create a reservation" do
      context "admin hold is not expired" do
        let!(:admin_reservation) { create(:admin_reservation, product: instrument, reserve_start_at: 30.minutes.from_now, duration: 1.hour) }

        it "cannot purchase" do
          click_link instrument.name
          select user.accounts.first.description, from: "Payment Source"

          # time is frozen to 9:30am, we expect the default time to be the end of the admin reservation
          expect(page.find_field("reservation_reserve_start_date").value).to eq Time.zone.today.strftime("%m/%d/%Y")
          expect(page.find_field("reservation_reserve_start_hour").value).to eq "11"
          expect(page.find_field("reservation_reserve_start_min").value).to eq "0"
          expect(page.find_field("reservation_reserve_start_meridian").value).to eq "AM"

          fill_in "Duration", with: 90
          select 10, from: "reservation_reserve_start_hour"
          select user.accounts.first.description, from: "Payment Source"
          click_button "Create"

          expect(page).to have_content "The reservation conflicts with another reservation."
        end
      end

      context "admin hold is expired" do
        let!(:admin_reservation) { create(:admin_reservation, product: instrument, reserve_start_at: 30.minutes.from_now, duration: 1.hour, deleted_at: 1.hour.ago) }

        it "can purchase" do

          click_link instrument.name
          select user.accounts.first.description, from: "Payment Source"
          fill_in "Duration", with: 90
          select 10, from: "reservation_reserve_start_hour"
          select user.accounts.first.description, from: "Payment Source"
          click_button "Create"

          expect(page).to have_content "Reservation created successfully"
        end
      end
    end

  end

end
