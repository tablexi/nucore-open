require 'spec_helper'
require 'controller_spec_helper'

describe OrderManagement::OrderDetailsController do
  before(:all) { create_users }
  let(:facility) { FactoryGirl.create(:setup_facility) }
  let(:item) { FactoryGirl.create(:setup_item, :facility => facility) }
  let(:instrument) { FactoryGirl.create(:setup_instrument, :facility => facility) }

  describe 'edit' do
    let(:item_order) { FactoryGirl.create(:purchased_order, :product => item) }
    let(:item_order_detail) { item_order.order_details.first }
    let(:reservation_order) { FactoryGirl.create(:purchased_reservation, :product => instrument) }
    before :each do
      @action = :edit
      @method = :get
    end

    context 'authentication' do
      before :each do
        @authable = facility
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
          journal.order_details << item_order_detail
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
end
