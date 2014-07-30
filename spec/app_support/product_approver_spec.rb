require 'spec_helper'

describe ProductApprover do
  let(:all_products) { create_list(:instrument_requiring_approval, 10, facility: facility) }
  let(:approver) { create(:user) }
  let(:facility) { create(:setup_facility) }
  let(:product) { all_products.first }
  let(:product_approver) { ProductApprover.new(all_products, user, approver) }
  let(:user) { create(:user) }

  context '#approve_access' do
    it 'grants usage approval to a product' do
      expect { product_approver.approve_access(product) }
        .to change{product.is_approved_for?(user)}.from(false).to(true)
      end
    end

  context '#disapprove_user' do
    before :each do
      product_approver.approve_access(product)
    end

    it 'revokes usage approval to a product' do
      expect { product_approver.revoke_access(product) }
        .to change{product.is_approved_for?(user)}.from(true).to(false)
    end
  end

  context '#update_approvals' do

    def verify_approvals(approved_products)
      all_products.each do |product|
        if approved_products.include?(product)
          expect(product.is_approved_for?(user)).to be_true
        else
          expect(product.is_approved_for?(user)).to be_false
        end
      end
    end

    it 'has no changes' do
      stats = product_approver.update_approvals([])

      expect(stats.any_changed?).to be_false
      expect(stats.granted).to eq 0
      expect(stats.revoked).to eq 0
    end

    it 'has approvals' do
      products_to_approve = all_products[0..3]
      stats = product_approver.update_approvals(products_to_approve)

      expect(stats.any_changed?).to be_true
      expect(stats.granted).to eq products_to_approve.count
      expect(stats.revoked).to eq 0

      verify_approvals(products_to_approve)
    end

    it 'has revocations' do
      all_products[0..3].each do |product|
        product_approver.approve_access(product)
      end

      stats = product_approver.update_approvals([])

      expect(stats.any_changed?).to be_true
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

      expect(stats.any_changed?).to be_true
      expect(stats.granted).to eq 1
      expect(stats.revoked).to eq 3

      verify_approvals(products_to_approve)
    end
  end
end
