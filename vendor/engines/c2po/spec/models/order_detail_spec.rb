require 'spec_helper'

describe OrderDetail do
  subject(:order_detail) { order.order_details.create(attributes_for(:order_detail).update(product_id: item.id, account_id: account.id)) }

  let(:account) { create(:purchase_order_account, account_users_attributes: account_users_attributes_hash(user: user)) }
  let(:facility) { create :facility }
  let(:facility_account) { facility.facility_accounts.create(attributes_for(:facility_account)) }
  let(:item) { facility.items.create(attributes_for(:item, facility_account_id: facility_account.id)) }
  let(:order) { user.orders.create(attributes_for(:order, created_by: user.id, account: account, facility: facility)) }
  let(:user) { create :user }

  before :each do
    Settings.order_details.status_change_hooks = nil

    expect(item).to be_valid
    expect(order).to be_valid
    expect(order_detail.state).to eq 'new'
    expect(order_detail.version).to eq 1
    expect(order_detail.order_status).to be_nil
  end

  context '#update_account' do
    let(:price_group) { create(:price_group, facility: facility) }
    let!(:price_policy) { create :item_price_policy, product: item, price_group: price_group }

    before :each do
      create :price_group_product, product: item, price_group: price_group, reservation_window: nil
      UserPriceGroupMember.create! price_group: price_group, user: user
    end

    context 'account is valid for the facility' do
      let(:new_account) { create(:purchase_order_account, account_users_attributes: account_users_attributes_hash(user: user)) }
      let(:original_statement) { create(:statement, facility: facility, created_by: user.id, account: account) }

      def move_to_new_account
        expect { order_detail.update_account(new_account) }
          .to change{order_detail.statement}.from(original_statement).to(nil)
        expect(order_detail.account).to be new_account
        original_statement.reload
      end

      context 'with estimated costs' do
        before :each do
          order_detail.update_attribute :statement_id, original_statement.id
          move_to_new_account
        end

        it 'should set estimated costs and assign account' do
          costs = price_policy.estimate_cost_and_subsidy(order_detail.quantity)
          expect(order_detail.estimated_cost).to eq costs[:cost]
          expect(order_detail.estimated_subsidy).to eq costs[:subsidy]
          expect(order_detail).to be_cost_estimated
        end
      end

      context 'with actual costs' do
        before :each do
          order_detail.update_attribute :statement_id, original_statement.id
          order_detail.update_attributes(actual_cost: 20, actual_subsidy: 10)
          order_detail.save!
          original_statement.add_order_detail(order_detail)
          original_statement.save!

          expect(original_statement.rows_for_order_detail(order_detail)).to be_one
        end

        it 'should remove itself from its statement' do
          expect { move_to_new_account }.to change{order_detail.statement}
            .from(original_statement).to(nil)
          expect(original_statement.rows_for_order_detail(order_detail)).to be_none
        end

        it 'should not have a statement date' do
          original_statement_date = order_detail.statement_date
          expect { move_to_new_account }.to change{order_detail.statement_date}
            .from(original_statement_date).to(nil)
        end
      end

      context 'state is complete' do
        before :each do
          order_detail.to_complete!
          order_detail.reviewed_at = 1.day.ago
          order_detail.save!
          expect(order_detail.state).to eq 'complete'
        end

        it 'should need a statement' do
          expect(OrderDetail.need_statement(facility).where(id: order_detail.id))
            .to eq [order_detail]
        end
      end
    end

    context 'account is invalid for the facility' do
      let(:cc_account) { create(:credit_card_account, account_users_attributes: account_users_attributes_hash(user: user)) }
      before :each do
        order_detail.facility.update_attributes(accepts_cc: false)
      end
      it 'should assign the account but not set estimated costs' do # TODO is this behavior correct?
        expect(order_detail.update_account(cc_account)).to be_nil
        expect(order_detail.account).to eq cc_account
      end
    end
  end
end
