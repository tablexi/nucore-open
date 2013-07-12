require 'spec_helper'
require 'controller_spec_helper'

describe OrderManagement::OrderDetailsController do
  before(:all) { create_users }
  let(:facility) { FactoryGirl.create(:setup_facility) }
  let(:item) { FactoryGirl.create(:setup_item, :facility => facility) }
  let(:instrument) { FactoryGirl.create(:setup_instrument, :facility => facility, :control_mechanism => 'timer') }

  before :each do
    @authable = facility
  end

  describe 'edit' do
    let(:item_order) { FactoryGirl.create(:purchased_order, :product => item) }
    let(:item_order_detail) { item_order.order_details.first }

    before :each do
      @action = :edit
      @method = :get
    end

    context 'authentication' do
      before :each do
        @params = { :facility_id => facility.url_name, :order_id => item_order.id, :id => item_order_detail.id }
      end
      it_should_allow_operators_only {}
    end

    context 'signed in' do
      render_views

      let(:dom) { Nokogiri::HTML(response.body) }

      before :each do
        sign_in @admin
        @params = { :facility_id => facility.url_name, :order_id => item_order.id, :id => item_order_detail.id }
      end

      context 'new order' do
        before :each do
          do_request
        end

        it 'is success' do
          expect(response).to be_success
        end

        it 'has new as a status' do
          expect(assigns(:order_statuses)).to include(OrderStatus.new_os.first)
        end

        it 'does not have a price policy' do
          expect(assigns(:order_detail).price_policy).to be_blank
        end

        it 'has estimated fields disabled' do
          cost = dom.css('#order_detail_estimated_cost').first
          expect(cost).to be_has_attribute('disabled')
          expect(cost['value']).to_not be_blank

          expect(dom.css('#order_detail_estimated_subsidy').first).to be_has_attribute('disabled')
          expect(dom.css('#order_detail_estimated_total').first).to be_has_attribute('disabled')
        end

        it 'has assigned user enabled' do
          expect(dom.css('#order_detail_assigned_user_id').first).to_not be_has_attribute('disabled')
        end
      end

      context 'completed order' do
        before :each do
          item_order_detail.change_status!(OrderStatus.complete.first)
        end

        context 'with a price policy' do
          context 'with a subsidy' do
            before :each do
              item_order_detail.price_policy.update_attributes(:unit_subsidy => 1)
              item_order_detail.assign_price_policy
              item_order_detail.save!
              do_request
            end

            it 'has actual fields' do
              cost = dom.css('#order_detail_actual_cost').first
              expect(cost).to be_present
              expect(cost['value']).to_not be_blank
            end

            it 'has the subsidy field enabled' do
              subsidy = dom.css('#order_detail_actual_subsidy').first
              expect(subsidy).to be_present
              expect(subsidy['value']).to_not be_blank
              expect(subsidy).to_not be_has_attribute('disabled')
            end
          end

          context 'without a subsidy' do
            before :each do
              item_order_detail.price_policy.update_attributes(:unit_subsidy => 0)
              item_order_detail.assign_price_policy
              item_order_detail.save!
              do_request
            end

            it 'has the subsidy field disabled' do
              subsidy = dom.css('#order_detail_actual_subsidy').first
              expect(subsidy).to be_has_attribute('disabled')
            end
          end
        end

        context 'without a price policy' do
          before :each do
            item.price_policies.delete_all
            item_order_detail.assign_estimated_price
            item_order_detail.assign_price_policy
            item_order_detail.save!
            expect(item_order_detail.price_policy).to be_blank
            do_request
          end

          it 'has a warning' do
            expect(dom.css('.alert')).to be_present
          end

          it 'has estimated fields disabled' do
            cost = dom.css('#order_detail_estimated_cost').first
            expect(cost).to be_has_attribute('disabled')
            expect(cost['value']).to be_blank
          end
        end
      end

      context 'order in open journal' do
        let(:journal) { FactoryGirl.create(:journal, :facility => facility) }
        before :each do
          item_order_detail.change_status!(OrderStatus.complete.first)
          item_order_detail.update_attributes(:reviewed_at => 1.day.ago)
          journal.create_journal_rows! [item_order_detail]
          item_order_detail.reload
          expect(item_order_detail.journal).to be_present

          do_request
        end

        it 'has an alert' do
          expect(dom.css('.alert')).to be_present
        end
      end
    end
  end

  describe 'update reservation' do
    let(:reservation) { FactoryGirl.create(:purchased_reservation, :product => instrument) }
    let(:order_detail) { reservation.order_detail }

    before :each do
      @action = :update
      @method = :post
      @params = { :facility_id => facility.url_name, :order_id => order_detail.order_id, :id => order_detail.id }
    end

    context 'authentication' do
      it_should_allow_operators_only(:redirect) {}
    end

    context 'while signed in' do
      before :each do
        sign_in @admin
      end

      describe 'updating reservation times' do
        before :each do
          instrument.price_policies.first.update_attributes(:reservation_rate => 0, :reservation_subsidy => 0, :usage_rate => 2, :usage_subsidy => 1)
        end

        context 'reserve times on incomplete order' do
          before :each do
            instrument.update_attributes(:min_reserve_mins => 1)
            @new_reserve_start = reservation.reserve_start_at + 1.hour
            @params[:order_detail] = {
              :reservation => {
                :reserve_start_at => @new_reserve_start,
                :duration_mins => 30
              }
            }
          end

          context 'does not conflict with another reservation' do
            before :each do
              do_request
            end

            it 'updates the reservation' do
              expect(reservation.reload.reserve_start_at).to eq(@new_reserve_start)
              expect(reservation.reserve_end_at).to eq(@new_reserve_start + 30.minutes)
            end

            it 'updates the estimated cost' do
              expect(order_detail.reload.estimated_cost).to eq(60)
              expect(order_detail.estimated_subsidy).to eq(30)
            end
          end

          context 'it conflicts with another reservation' do
            before :each do
              @other_reservation = FactoryGirl.create(:purchased_reservation,
                  :reserve_start_at => @new_reserve_start,
                  :reserve_end_at => @new_reserve_start + 1.hour,
                  :product => instrument)
              @old_start_time = reservation.reserve_start_at
              do_request
            end

            it 'does not save the reservation' do
              expect(assigns(:order_detail).reservation).to be_changed
            end

            it 'sets the flash' do
              expect(flash[:error]).to be_present
            end

            it 'renders error' do
              expect(response).to render_template(:edit)
              expect(response.code).to eq('406')
            end
          end
        end

      end

      describe 'cancelling an order' do
        before :each do
          instrument.update_attributes!(:min_cancel_hours => 72)
          instrument.price_policies.first.update_attributes(:cancellation_cost => 100, :reservation_rate => 0, :reservation_subsidy => 0)
          @params[:order_detail] = {
            :order_status_id => OrderStatus.cancelled.first.id.to_s
          }
        end

        context 'with cancellation fee' do
          before :each do
            @params[:with_cancel_fee] = "1"
            do_request
          end

          it 'cancels the order detail and reservation' do
            expect(assigns(:order_detail).order_status.name).to eq('Cancelled')
            expect(assigns(:order_detail).reservation).to be_cancelled
          end

          it 'assigns the cancellation fee' do
            expect(assigns(:order_detail).actual_total).to eq(100)
          end
        end

        context 'without cancellation fee' do
          before :each do
            do_request
          end

          it 'cancels the order detail and reservation' do
            expect(assigns(:order_detail).order_status.name).to eq('Cancelled')
            expect(assigns(:order_detail).reservation).to be_cancelled
          end

          it 'does not assign the cancellation fee' do
            expect(assigns(:order_detail).actual_total.to_i).to eq(0)
          end
        end
      end

    end
  end

  describe 'updating item' do
    let(:order) { FactoryGirl.create(:purchased_order, :product => item) }
    let(:order_detail) { order.order_details.first }

    before :each do
      sign_in @admin
      @action = :update
      @method = :post
      @params = { :facility_id => facility.url_name, :order_id => order_detail.order_id, :id => order_detail.id }
    end

    describe 'updating pricing' do
      before :each do
        order_detail.change_status!(OrderStatus.complete.first)
      end

      it 'updates the price manually' do
        @params[:order_detail] = {
          :actual_cost    => "20.00",
          :actual_subsidy => "4.00"
        }
        do_request
        expect(order_detail.reload.actual_total).to eq(16.00)
      end

      it 'returns an error when trying to set subsidy more than quantity' do
        @params[:order_detail] = {
            :actual_cost    => "10.00",
            :actual_subsidy => "11.00"
        }
        do_request
        expect(assigns(:order_detail).errors).to include(:actual_total)
      end
    end

    describe 'resolving dispute' do
      before :each do
        order_detail.change_status!(OrderStatus.complete.first)
        order_detail.update_attributes(:reviewed_at => Time.zone.now, :dispute_at => Time.zone.now, :dispute_reason => 'silly reason')
        @params[:order_detail] = {}
      end

      context 'checked' do
        before :each do
          @params[:order_detail][:resolve_dispute] = '1'
        end

        it 'resolves the dispute if checked and noted' do
          @params[:order_detail][:dispute_resolved_reason] = 'dispute resolved'
          do_request
          expect(assigns(:order_detail).dispute_resolved_at).to be
          expect(order_detail.reload.dispute_resolved_at).to be
          expect(order_detail.dispute_resolved_reason).to eq('dispute resolved')
        end

        it 'errors if checked and not noted' do
          @params[:order_detail][:dispute_resolved_reason] = ''
          do_request
          expect(response).to render_template(:edit)
          expect(assigns(:order_detail).errors).to include(:dispute_resolved_reason)
          expect(assigns(:order_detail).dispute_resolved_at).to be_nil
        end
      end

      it 'does not resolve if not checked' do
        @params[:order_detail][:resolve_dispute] = "0"
        do_request
        expect(assigns(:order_detail).dispute_resolved_at).to be_nil
        expect(order_detail.reload.dispute_resolved_at).to be_nil
      end
    end
  end

  describe 'pricing' do
    let(:reservation) { FactoryGirl.create(:purchased_reservation, :product => instrument) }
    let(:order_detail) { reservation.order_detail }
    let(:price_policy) { instrument.price_policies.first }

    before :each do
      @action = :pricing
      @method = :get
      @params = { :facility_id => facility.url_name, :order_id => order_detail.order.id, :id => order_detail.id }
    end

    context 'authorization' do
      it_should_allow_operators_only {}
    end

    context 'signed in' do
      before :each do
        sign_in @admin
        expect(instrument.price_policies).to be_one
        price_policy.update_attributes(:reservation_rate => 0, :reservation_subsidy => 0, :usage_rate => 2, :usage_subsidy => 1)
        order_detail.assign_estimated_price
        order_detail.save
      end

      it 'has the correct original price' do
        expect(order_detail.estimated_total).to eq(reservation.duration_mins)
      end

      context 'incomplete reservation' do
        let(:new_duration) { 73 }
        let(:json_response) { JSON.parse(response.body) }
        before :each do
          @params[:order_detail] = {
              :reservation => {
                :reserve_start_at => reservation.reserve_start_at,
                :duration_mins => new_duration
              }
            }
          do_request
        end

        it 'is successful' do
          expect(response).to be_success
        end

        it 'returns a new estimated price' do
          expect(json_response['estimated_cost'].to_i).to eq(new_duration * 2)
          expect(json_response['estimated_subsidy'].to_i).to eq(new_duration)
          expect(json_response['estimated_total'].to_i).to eq(new_duration)
        end

        it 'does not return actual price' do
          expect(json_response['actual_cost']).to be_blank
          expect(json_response['actual_subsidy']).to be_blank
          expect(json_response['actual_total']).to be_blank
        end

        it 'does not actually update the order detail' do
          expect(reservation.reload.duration_mins).to eq(60)
          expect(order_detail.reload.estimated_total).to eq(60)
        end
      end

      context 'completed reservation' do
        let(:new_duration) { 73 }
        let(:json_response) { JSON.parse(response.body) }
        before :each do
          reservation.update_attributes(:reserve_start_at => reservation.reserve_start_at - 2.days, :reserve_end_at => reservation.reserve_end_at - 2.days)
          order_detail.update_order_status! @admin, OrderStatus.complete.first
          @params[:order_detail] = {
              :reservation => {
                :reserve_start_at => reservation.reserve_start_at,
                :duration_mins => reservation.duration_mins,
                :actual_start_at => reservation.reserve_start_at,
                :actual_duration_mins => new_duration
              }
            }
          expect(order_detail).to be_complete
        end

        context 'with a valid price policy' do
          before :each do
            do_request
          end

          it 'is successful' do
            expect(response).to be_success
          end

          it 'returns a new actual price' do
            expect(json_response['actual_cost'].to_i).to eq(new_duration * 2)
            expect(json_response['actual_subsidy'].to_i).to eq(new_duration)
            expect(json_response['actual_total'].to_i).to eq(new_duration)
          end

          it 'does not actually update the order detail' do
            expect(reservation.reload.duration_mins).to eq(60)
            expect(order_detail.reload.estimated_total).to eq(60)
          end
        end

        context 'without a valid price policy' do
          before :each do
            instrument.price_policies.delete_all
            order_detail.assign_price_policy
            order_detail.save!
            expect(order_detail.price_policy).to be_blank
            do_request
          end

          it 'is successful' do
            expect(response).to be_success
          end

          it 'does not return an estimated price' do
            expect(json_response['estimated_cost']).to be_blank
            expect(json_response['estimated_subsidy']).to be_blank
            expect(json_response['estimated_total']).to be_blank
          end

          it 'does not return actual price' do
            expect(json_response['actual_cost']).to be_blank
            expect(json_response['actual_subsidy']).to be_blank
            expect(json_response['actual_total']).to be_blank
          end

          it 'does not actually update the order detail' do
            expect(reservation.reload.duration_mins).to eq(60)
            expect(order_detail.reload.estimated_total).to eq(60)
          end
        end
      end
    end
  end
end
