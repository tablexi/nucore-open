require 'spec_helper'

describe ProductApprover do
  let(:all_products) { create_list(:instrument_requiring_approval, 10, facility: facility) }
  let(:approver) { create(:user) }
  let(:expert_access_group) { create(:product_access_group, name: 'Expert', product: product) }
  let(:facility) { create(:setup_facility) }
  let(:novice_access_group) { create(:product_access_group, name: 'Novice', product: product) }
  let(:product) { all_products.first }
  let(:product_approver) { ProductApprover.new(all_products, user, approver) }
  let(:product_user) { product.find_product_user(user) }
  let(:schedule_rule) { product.schedule_rules.create(attributes_for :schedule_rule) }
  let(:user) { create(:user) }

  def set_up_access_list
    schedule_rule.product_access_groups = [expert_access_group, novice_access_group]
    product.product_users.create(product: product, user: user, approved_by: user.id)
    product_user.product_access_group = novice_access_group
    product_user.save
  end

  context '#approve_access' do
    it 'grants usage approval to a product' do
      expect { product_approver.approve_access(product) }
        .to change{product.can_be_used_by?(user)}.from(false).to(true)
    end

    it 'grants usage approval to a product' do
      expect { product_approver.approve_access(product) }
        .to change{product.can_be_used_by?(user)}.from(false).to(true)
    end
  end

  context '#revoke_access' do
    before :each do
      product_approver.approve_access(product)
    end

    it 'revokes usage approval to a product' do
      expect { product_approver.revoke_access(product) }
        .to change{product.can_be_used_by?(user)}.from(true).to(false)
    end
  end

  context '#update_approvals' do

    def verify_approvals(approved_products)
      all_products.each do |product|
        if approved_products.include?(product)
          expect(product.can_be_used_by?(user)).to be_true
        else
          expect(product.can_be_used_by?(user)).to be_false
        end
      end
    end

    it 'has no changes' do
      stats = product_approver.update_approvals([], {})

      expect(stats).not_to be_grants_changed
      expect(stats.granted).to eq 0
      expect(stats.revoked).to eq 0
      expect(stats).not_to be_access_groups_changed
    end

    context 'with access groups' do
      let(:products_to_approve) { all_products[0..3] }
      let(:stats) { product_approver.update_approvals(products_to_approve, access_group_hash) }

      before :each do
        set_up_access_list
      end

      context 'when an access group changes' do
        let(:access_group_hash) { { product.id.to_s => expert_access_group.id } }

        it 'has approvals' do
          expect(stats).to be_grants_changed
          expect(stats.granted).to eq(products_to_approve.count - 1)
          expect(stats.revoked).to eq 0
          expect(stats).to be_access_groups_changed
          expect(stats.access_groups_changed).to eq 1

          verify_approvals(products_to_approve)
        end
      end

      context 'when access groups stay the same' do
        let(:access_group_hash) { { product.id.to_s => novice_access_group.id } }

        it 'has approvals' do
          expect(stats).to be_grants_changed
          expect(stats.granted).to eq(products_to_approve.count - 1)
          expect(stats.revoked).to eq 0
          expect(stats).not_to be_access_groups_changed
          expect(stats.access_groups_changed).to eq 0

          verify_approvals(products_to_approve)
        end
      end
    end

    it 'has revocations' do
      all_products[0..3].each do |product|
        product_approver.approve_access(product)
      end

      stats = product_approver.update_approvals([])

      expect(stats).to be_grants_changed
      expect(stats.granted).to eq 0
      expect(stats.revoked).to eq 4

      verify_approvals([])
    end

    it 'has both approvals and revocations' do
      initially_approved_products = all_products[0..4]
      initially_approved_products.each do |product|
        product_approver.approve_access(product)
      end

      products_to_approve = all_products[3..5]
      stats = product_approver.update_approvals(products_to_approve)

      expect(stats).to be_grants_changed
      expect(stats.granted).to eq 1
      expect(stats.revoked).to eq 3

      verify_approvals(products_to_approve)
    end
  end
end
