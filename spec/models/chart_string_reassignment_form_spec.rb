require 'spec_helper'

describe ChartStringReassignmentForm do

  describe '#available_accounts' do
    let(:accounts) { (0..8).map { |n| double Account, description: "Account #{n}" } }
    let(:order_details) { (0..8).map { double OrderDetail } }
    let(:users) { (0..2).map { double User } }

    def random_items(list, count)
      list.shuffle.slice(0, count)
    end

    def random_item(list)
      list[rand(list.length)]
    end

    context 'with a single User' do
      it 'determines available accounts' do
        order_detail = order_details.first
        order_detail.stub(:account) { accounts.first }
        user = users.first
        user.stub(:accounts) { accounts }
        order_detail.stub(:user) { user }

        form = ChartStringReassignmentForm.new([order_detail])
        expect(form.available_accounts).to eq(user.accounts)
      end
    end

    context 'with multiple Users' do
      context 'Users have all accounts in common' do
        it 'determines available_accounts' do
          users.each do |user|
            user.stub(:accounts) { accounts }
          end
          order_details.each_with_index do |order_detail, n|
            order_detail.stub(:account) { random_item(accounts) }
            order_detail.stub(:user) { users[n % users.length] }
          end

          form = ChartStringReassignmentForm.new(order_details)
          expect(form.available_accounts).to eq(accounts)
        end
      end

      context 'Users have some accounts in common' do
        it 'determines available_accounts' do
          common_accounts = [ accounts.first, accounts.last ]
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

          form = ChartStringReassignmentForm.new(order_details)
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

          form = ChartStringReassignmentForm.new(order_details)
          expect(form.available_accounts).to eq accounts
        end
      end
    end
  end
end
