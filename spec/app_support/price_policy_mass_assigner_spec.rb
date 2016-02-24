require "rails_helper"

RSpec.describe PricePolicyMassAssigner do
  context ".assign_price_policies" do
    let(:account) { create(:setup_account, owner: user) }
    let(:facility) { create(:facility) }
    let(:facility_account) do
      facility.facility_accounts.create(facility_account_attributes)
    end
    let(:facility_account_attributes) { attributes_for(:facility_account) }
    let(:fulfilled_at) { nil }
    let(:item_attributes) do
      attributes_for(:item, facility_account_id: facility_account.id)
    end
    let(:order) { user.orders.create(order_attributes) }
    let(:order_attributes) do
      attributes_for(:order,
                     created_by: user.id,
                     account: account,
                     facility: facility,
                    )
    end
    let(:order_detail) do
      create(:order_detail,
             account: account,
             fulfilled_at: fulfilled_at,
             order: order,
             product: product,
            )
    end
    let(:price_group) { create(:price_group, facility: facility) }
    let(:product) { facility.items.create(item_attributes) }
    let(:user) { create(:user) }

    def mass_assign_price_policies
      PricePolicyMassAssigner.assign_price_policies([order_detail])
    end

    context "when compatible price policies exist" do
      before :each do
        create(:account_price_group_member, account: account, price_group: price_group)
      end

      let!(:previous_price_policy) do
        product.item_price_policies.create(attributes_for(:item_price_policy,
                                                          price_group_id: price_group.id,
                                                          start_date: 8.years.ago,
                                                          expire_date: nil,
                                                         ))
      end

      let!(:current_price_policy) do
        product.item_price_policies.create(attributes_for(:item_price_policy,
                                                          price_group_id: price_group.id,
                                                          start_date: 1.day.ago,
                                                          expire_date: nil,
                                                         ))
      end

      context "when order details are fulfilled" do
        context "at a time matching a past price policy" do
          let(:fulfilled_at) { previous_price_policy.start_date + 1.day }

          it "assigns the past price policy" do
            expect(mass_assign_price_policies).to eq [order_detail]
            expect(order_detail.price_policy).to eq previous_price_policy
          end
        end

        context "at a time matching the current price policy" do
          let(:fulfilled_at) { current_price_policy.start_date + 1.day }

          it "assigns the current price policy" do
            expect(mass_assign_price_policies).to eq [order_detail]
            expect(order_detail.price_policy).to eq current_price_policy
          end
        end

        context "at a time matching no price policies" do
          let(:fulfilled_at) { previous_price_policy.start_date - 1.day }

          it "assigns no price policies" do
            expect(mass_assign_price_policies.size).to eq(0)
            expect(order_detail.price_policy).to be_blank
          end
        end
      end

      context "when order details are unfulfilled" do
        it "assigns the current price policy" do
          expect(mass_assign_price_policies).to eq [order_detail]
          expect(order_detail.price_policy).to eq current_price_policy
        end
      end
    end

    context "when no compatible price policies exist" do
      it "assigns no price policies" do
        expect(mass_assign_price_policies.size).to eq(0)
        expect(order_detail.price_policy).to be_blank
      end
    end
  end
end
