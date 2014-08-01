require 'spec_helper'

describe StatementRow do
  # TODO reduce this elaborate setup!
  let(:account) { create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: user)) }
  let(:facility) { create(:facility) }
  let(:facility_account) { facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account)) }
  let(:order) { user.orders.create(FactoryGirl.attributes_for(:order, facility_id: facility.id, account_id: account.id, created_by: user.id)) }
  let(:order_detail) { order.order_details.create(FactoryGirl.attributes_for(:order_detail).update(product_id: service.id, account_id: account.id)) }
  let(:service) { facility.services.create(FactoryGirl.attributes_for(:service, facility_account_id: facility_account.id)) }
  let(:statement) { create(:statement, facility: facility, created_by: user.id, account: account) }
  let(:user) { create(:user) }

  it 'should create without error' do
    expect { StatementRow.create!(statement: statement, order_detail: order_detail) }
      .to_not raise_error
  end

  it { should validate_presence_of :order_detail_id }
  it { should validate_presence_of :statement_id }
end
