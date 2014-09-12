require 'spec_helper'

describe ChartStringReassignmentForm do
  let(:order) { create(:purchased_order, product: product) }
  let(:product) { create(:setup_item) }

  def create_order_detail
    create(:order_detail, order: order, product: product)
  end

  def create_order_details(n)
    n.times.map { create_order_detail }
  end

  describe '#available_accounts' do
    let(:accounts) { create_list(:setup_account, 9, owner: users.first) }
    let(:order_details) { create_order_details(9) }
    let(:users) { create_list(:user, 3) }

    def random_items(list, count)
      list.shuffle.slice(0, count)
    end

    def random_item(list)
      list[rand(list.length)]
    end

    context 'with a single User' do
      subject(:form) { ChartStringReassignmentForm.new([order_detail]) }
      let(:order_detail) { create_order_detail }
      let(:user) { users.first }

      before :each do
        order.update_attribute(:user_id, user.id)
        order_detail.update_attribute(:account_id, accounts.first.id)
      end

      it 'has available accounts' do
        expect(form.available_accounts.count).to eq accounts.count
      end

      it 'determines available accounts' do
        expect(form.available_accounts).to eq(user.accounts)
      end
    end

    context 'with multiple Users' do
      subject(:form) { ChartStringReassignmentForm.new(order_details) }

      context 'Users have all accounts in common' do
        it 'determines available_accounts' do
          users.each do |user|
            user.stub(:accounts) { accounts }
          end
          order_details.each_with_index do |order_detail, n|
            order_detail.stub(:account) { random_item(accounts) }
            order_detail.stub(:user) { users[n % users.length] }
          end

          expect(form.available_accounts).to eq(accounts)
        end
      end

      context 'Users have some accounts in common' do
        let(:common_accounts) { [ accounts.first, accounts.last ] }

        it 'determines available_accounts' do
          all_user_accounts = Set.new
          users.each do |user|
            user_accounts = (common_accounts + random_items(accounts, 4)).uniq
            user.stub(:accounts) { user_accounts }
            all_user_accounts += user_accounts
          end

          order_details.each_with_index do |order_detail, n|
            order_detail.stub(:account) { double Account }
            order_detail.stub(:user) { users[n % users.length] }
          end

          expect(form.available_accounts).to eq all_user_accounts.sort_by(&:description)
        end
      end

      context 'Users have no accounts in common' do
        it 'determines available_accounts' do
          n = 0
          accounts.each_slice(3) do |account_block|
            users[n].stub(:accounts) { account_block }
            n += 1
          end
          order_details.each_with_index do |order_detail, n|
            order_detail.stub(:account) { double Account }
            order_detail.stub(:user) { users[n % users.length] }
          end

          expect(form.available_accounts).to eq accounts
        end
      end
    end
  end
end
