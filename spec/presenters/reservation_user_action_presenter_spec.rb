require 'spec_helper'

describe ReservationUserActionPresenter do
  include Rails.application.routes.url_helpers

  let(:facility) { mock_model Facility }
  let(:order) { mock_model Order, facility: facility }
  let(:order_detail) { mock_model OrderDetail, order: order, accessories?: false }
  let(:reservation) do
    mock_model Reservation, order_detail: order_detail, order: order,
       can_switch_instrument?: true,
       can_switch_instrument_off?: false,
       can_switch_instrument_on?: false,
       can_move?: false,
       can_cancel?: false
  end
  let(:template) { double('template') }

  subject(:presenter) { described_class.new(template, reservation) }

  describe 'view_edit_link' do
    describe 'when in a current facility' do
      before { allow(template).to receive(:current_facility).and_return facility }

      it 'returns an edit link when the user can edit' do
        expect(reservation).to receive(:can_customer_edit?).and_return true
        path = edit_facility_order_order_detail_reservation_path(facility, order, order_detail, reservation)
        link = double 'link'
        expect(presenter).to receive(:link_to).with(reservation, path).and_return link
        expect(presenter.view_edit_link).to eq(link)
      end

      it 'returns a view link if the user cannot edit' do
        expect(reservation).to receive(:can_customer_edit?).and_return false
        path = facility_order_order_detail_reservation_path(facility, order, order_detail, reservation)
        link = double 'link'
        expect(presenter).to receive(:link_to).with(reservation, path).and_return link
        expect(presenter.view_edit_link).to eq(link)
      end
    end

    describe 'when not in a current facility' do
      before { allow(template).to receive(:current_facility).and_return nil }

      it 'returns an edit link when the user can edit' do
        expect(reservation).to receive(:can_customer_edit?).and_return true
        path = edit_order_order_detail_reservation_path(order, order_detail, reservation)
        link = double 'link'
        expect(presenter).to receive(:link_to).with(reservation, path).and_return link
        expect(presenter.view_edit_link).to eq(link)
      end

      it 'returns a view link if the user cannot edit' do
        expect(reservation).to receive(:can_customer_edit?).and_return false
        path = order_order_detail_reservation_path(order, order_detail, reservation)
        link = double 'link'
        expect(presenter).to receive(:link_to).with(reservation, path).and_return link
        expect(presenter.view_edit_link).to eq(link)
      end
    end
  end

  describe 'user_actions' do
    subject(:text) { presenter.user_actions }
    it 'is blank by default' do
      expect(text).to be_blank
    end

    describe 'switching' do
      describe 'can switch on' do
        before { expect(reservation).to receive(:can_switch_instrument_on?).and_return true }

        it 'includes the switch on event' do
          link = order_order_detail_reservation_switch_instrument_path(order, order_detail, reservation, :switch => 'on')
          expect(text).to include link
        end
      end

      describe 'can switch off' do
        before { expect(reservation).to receive(:can_switch_instrument_off?).and_return true }
        it 'includes the switch off event' do
          link = order_order_detail_reservation_switch_instrument_path(order, order_detail, reservation, :switch => 'off')
          expect(text).to include link
        end
      end
    end

    describe 'cancelling' do
      before { expect(reservation).to receive(:can_cancel?).and_return true }

      context 'there is a fee' do
        before { expect(order_detail).to receive(:cancellation_fee).and_return 10 }

        it 'includes a cancelation link with a confirmation' do
          link = order_order_detail_path(order, order_detail, cancel: 'cancel')
          expect(text).to include link
          expect(text).to include 'confirm="Canceling this reservation will incur a $10'
        end
      end

      context 'there is not a fee' do
        before { expect(order_detail).to receive(:cancellation_fee).and_return 0 }
        it 'includes a cancelation link without a confirmation' do
          link = order_order_detail_path(order, order_detail, cancel: 'cancel')
          expect(text).to include link
          expect(text).to include "confirm="
          expect(text).to_not include "will incur a $"
        end
      end
    end

    describe 'moving' do
      before do
        expect(reservation).to receive(:can_switch_instrument?).and_return false
        expect(reservation).to receive(:can_move?).and_return true
      end

      it 'includes the move link' do
        link = order_order_detail_reservation_move_reservation_path(order, order_detail, reservation)
        expect(text).to include link
      end
    end
  end
end
