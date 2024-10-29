# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SingleReservations" do
  let(:instrument) do
    FactoryBot.create(
      :setup_instrument,
      :always_available,
      pricing_mode:
    )
  end
  let(:facility) { instrument.facility }
  let(:user) { FactoryBot.create(:user) }
  let(:price_policy) do
    FactoryBot.create(
      :instrument_price_policy,
      price_group: PriceGroup.base,
      product: instrument
    )
  end
  let(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let(:instrument_args) { {} }

  before do
    FactoryBot.create(:account_price_group_member, account:, price_group: price_policy.price_group)
    login_as user
  end

  describe "daily booking instrument" do
    let(:pricing_mode) { Instrument::Pricing::SCHEDULE_DAILY }

    it "allows to make a reservation", :js do
      visit new_facility_instrument_single_reservation_path(facility, instrument)

      expect(page).to have_content("Create Reservation")
      expect(page).to have_content("Duration days")

      date_start = 1.day.from_now.to_date
      date_end = 2.days.from_now.to_date
      duration_days = 2

      fill_in("reservation[reserve_start_date]", with: I18n.l(date_start, format: :usa))
      fill_in("reservation[duration_days]", with: duration_days)

      # it autofills the end date
      find_field("reservation[reserve_end_date]", type: "hidden").tap do |field|
        expect(field.value).to eq(I18n.l(date_end, format: :usa))
      end

      click_button("Create")

      expect(page).to have_content("Reservation created successfully")
    end
  end
end
