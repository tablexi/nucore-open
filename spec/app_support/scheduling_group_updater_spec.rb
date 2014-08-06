require 'spec_helper'

describe SchedulingGroupUpdater do
  let(:expert_access_group) { create(:product_access_group, name: 'Expert', product: product) }
  let(:facility) { create(:setup_facility) }
  let(:novice_access_group) { create(:product_access_group, name: 'Novice', product: product) }
  let(:product) { create(:instrument_requiring_approval, facility: facility) }
  let(:product_user) { product.find_product_user(user) }
  let(:schedule_rule) { product.schedule_rules.create(attributes_for :schedule_rule) }
  let(:updater) { SchedulingGroupUpdater.new(product.id, user) }
  let(:user) { create(:user) }

  context '#update_access_group' do
    context 'product has user access list' do
      before :each do
        schedule_rule.product_access_groups = [expert_access_group, novice_access_group]
        product.product_users.create(product: product, user: user, approved_by: user.id)
        product_user.product_access_group = novice_access_group
        product_user.save
      end

      context 'new access group is different' do
        it 'updates' do
          expect { updater.update_access_group(expert_access_group.id) }
            .to change{product_user.reload.product_access_group}
            .from(novice_access_group).to(expert_access_group)
        end
      end

      context 'new access group is the same' do
        it 'does not update' do
          expect { updater.update_access_group(novice_access_group.id) }
            .not_to change{product_user.reload.product_access_group}
        end
      end

      context 'the new access group is nothing' do
        it 'updates' do
          expect { updater.update_access_group(0) }
            .to change{product_user.reload.product_access_group}
            .from(novice_access_group).to(nil)
        end
      end
    end

    context 'product has no user access list' do
      it 'does not update' do
        expect(updater.update_access_group(novice_access_group.id)).to be_false
      end
    end
  end
end
