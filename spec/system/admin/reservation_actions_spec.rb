# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reservation actions", :js, feature_setting: { cross_core_order_view: true } do
  let(:facility) { create(:setup_facility) }
  let(:facility_administrator) { create(:user, :facility_administrator, facility:) }
  let(:accounts) { create_list(:setup_account, 2) }
  let(:item) { create(:setup_item, facility:) }
  let!(:cross_core_order_originating_facility) { create(:purchased_order, product: item, account: accounts.first) }

  let(:facility2) { create(:setup_facility) }
  let(:facility2_instrument) { create(:setup_instrument, facility: facility2) }
  let!(:reservation) { create(:setup_reservation) }

  let(:cross_core_project) { create(:project, facility:, name: "#{facility.abbreviation}-#{cross_core_order_originating_facility.id}") }

  before do
    cross_core_order_originating_facility.update!(cross_core_project:)
    login_as facility_administrator
  end

  # Most likely need to set up the reservation doing something like this
  # @order_detail_reservation = setup_reservation(@authable, @account, @director)
  # @reservation = place_reservation(@authable, @order_detail_reservation, Time.zone.now + 1.hour)

  xdescribe "" do
    context "" do
      it "" do
        expect(true).to be_truthy
      end
    end
  end
end
