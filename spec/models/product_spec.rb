require "rails_helper"

RSpec.describe Product do
  describe "with everything configured" do
    subject(:product) { create(:instrument_requiring_approval) }

    let(:access_group) { create(:product_access_group, product: product) }
    let(:facility) { @facility }
    let!(:product_user) { product.product_users.create(product: product, user: user, approved_by: user.id) }
    let(:schedule_rule) { product.schedule_rules.create(attributes_for :schedule_rule) }
    let(:user) { create(:user) }

    class TestProduct < Product

      def account_required
        false
      end

    end

    before :each do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    end

    it "should not create using factory" do
      @product = Product.create(FactoryGirl.attributes_for(:item, facility_account_id: @facility_account.id))
      expect(@product.errors[:type]).not_to be_nil
    end

    context "with item" do
      before :each do
        @item = @facility.items.create(FactoryGirl.attributes_for(:item, facility_account_id: @facility_account.id))
      end

      it "should create map to default price groups" do
        expect(PriceGroupProduct.where(product_id: @item.id).count)
          .to eq PriceGroup.globals.count
        expect(PriceGroupProduct.find_by_product_id_and_price_group_id(@item.id, PriceGroup.base.first.id)).not_to be_nil
        expect(PriceGroupProduct.find_by_product_id_and_price_group_id(@item.id, PriceGroup.external.first.id)).not_to be_nil
      end

      it "should give correct initial order status" do
        os = OrderStatus.inprocess.first
        @item.update_attribute(:initial_order_status_id, os.id)
        expect(@item.initial_order_status).to eq(os)
      end

      it "should give default order status if status not set" do
        expect(Item.new.initial_order_status).to eq(OrderStatus.default_order_status)
      end
    end

    context "with price policies" do
      subject(:instrument) { create(:instrument_requiring_approval) }

      before { instrument.price_policies.each(&:delete) }

      let!(:current_price_policies) do
        3.times.map do
          create(:instrument_price_policy,
                 product: instrument,
                 start_date: 3.days.ago,
                 expire_date: 3.days.from_now,
                )
        end
      end

      let!(:past_price_policies) do
        [4, 1, 5, 3, 2].map do |n|
          create(:instrument_price_policy,
                 product: instrument,
                 start_date: n.months.ago,
                 expire_date: n.months.ago + 2.weeks,
                )
        end
      end

      let!(:upcoming_price_policies) do
        [4, 1, 5, 3, 2].map do |n|
          create(:instrument_price_policy,
                 product: instrument,
                 start_date: n.months.from_now,
                 expire_date: n.months.from_now + 2.weeks,
                )
        end
      end

      context "#current_price_policies" do
        it "returns current price policies" do
          expect(instrument.current_price_policies).to eq current_price_policies
        end
      end

      context "#past_price_policies" do
        it "returns past_price_policies" do
          expect(instrument.past_price_policies).to eq past_price_policies
        end
      end

      context "#past_price_policies_grouped_by_start_date" do
        let(:policies) { instrument.past_price_policies_grouped_by_start_date }

        it "groups and sorts policies in descending chronological order" do
          expect(policies.keys).to eq policies.keys.sort.reverse
        end
      end

      context "#upcoming_price_policies" do
        it "returns upcoming_price_policies" do
          expect(instrument.upcoming_price_policies).to eq upcoming_price_policies
        end
      end

      context "#upcoming_price_policies_grouped_by_start_date" do
        let(:policies) { instrument.upcoming_price_policies_grouped_by_start_date }

        it "groups and sorts policies in ascending chronological order" do
          expect(policies.keys).to eq policies.keys.sort
        end
      end
    end

    context "email" do
      before :each do
        @facility = FactoryGirl.create(:facility, email: "facility@example.com")
        @product = TestProduct.create!(contact_email: "product@example.com", facility: @facility, name: "Test Product", url_name: "test")
      end

      before :all do
        SettingsHelper.enable_feature(:expense_accounts, false)
      end

      after :all do
        reset_settings
      end

      context "product specific enabled" do
        before :all do
          @original_setting = SettingsHelper.feature_on? :product_specific_contacts
          SettingsHelper.enable_feature(:product_specific_contacts)
        end
        after :all do
          SettingsHelper.enable_feature(:product_specific_contacts, @original_setting)
        end

        it "should return the product's email if it has it" do
          expect(@product.email).to eq("product@example.com")
        end
        it "should return the facility's email if no product email" do
          @product.contact_email = ""
          expect(@product.email).to eq("facility@example.com")
        end
        it "should validate with the product email set" do
          expect(@product).to be_valid
        end
        it "should validate with the facility's email set" do
          @product.contact_email = ""
          expect(@product).to be_valid
        end
        it "should not validate without an email on either product or facility" do
          @facility.update_attributes!(email: "")
          @product.contact_email = ""
          expect(@product).not_to be_valid
          expect(@product.errors.full_messages).to include "Contact email must be set on either the product or the facility"
        end
      end
      context "product specific disabled" do
        before :all do
          @original_setting = SettingsHelper.feature_on? :product_specific_contacts
          SettingsHelper.enable_feature(:product_specific_contacts, false)
        end
        after :all do
          SettingsHelper.enable_feature(:product_specific_contacts, @original_setting)
        end
        it "should return the facility's email address even if the product has an email" do
          expect(@product.email).to eq("facility@example.com")
        end
        it "should validate if the product email is set" do
          expect(@product).to be_valid
        end
        it "should validate if the product email is not set, but the the facility is" do
          @product.contact_email = ""
          expect(@product).to be_valid
        end
        it "should validate even if the facility's email is blank" do
          @facility.update_attributes!(email: "")
          @product.contact_email = ""
          expect(@product).to be_valid
        end
      end
    end

    context "can_purchase?" do
      class TestPricePolicy < PricePolicy
      end
      before :each do
        @product = TestProduct.create!(facility: @facility, name: "Test Product", url_name: "test")
        @price_group = FactoryGirl.create(:price_group, facility: @facility)
        @price_group2 = FactoryGirl.create(:price_group, facility: @facility)
        @user = FactoryGirl.create(:user)
        FactoryGirl.create(:user_price_group_member, user: @user, price_group: @price_group)
        @user.reload

        @user_price_group_ids = @user.price_groups.map(&:id)
      end
      it "should not be purchasable if it is archived" do
        @product.update_attributes is_archived: true
        expect(@product).not_to be_available_for_purchase
      end

      it "should not be purchasable if the facility is inactive" do
        @product.facility.update_attributes is_active: false
        expect(@product).not_to be_available_for_purchase
      end

      it "should not be purchasable if you pass it empty groups" do
        expect(@product).not_to be_can_purchase([])
      end

      it "should not be purchasable if there are no pricing rules ever" do
        expect(@product).not_to be_can_purchase(@user_price_group_ids)
      end

      it "should not be purchasable if there is no price rule for a user, but there are current price rules" do
        @price_policy = TestPricePolicy.create!(price_group: @price_group2,
                                                product: @product,
                                                start_date: Time.zone.now - 1.day,
                                                expire_date: Time.zone.now + 7.days,
                                                can_purchase: true)
        expect(@product).not_to be_can_purchase(@user_price_group_ids)
      end

      it "should be purchasable if there is a current price rule for the user's group" do
        @price_policy = TestPricePolicy.create!(price_group: @price_group,
                                                product: @product,
                                                start_date: Time.zone.now - 1.day,
                                                expire_date: Time.zone.now + 7.days,
                                                can_purchase: true)
        expect(@product).to be_can_purchase(@user_price_group_ids)
      end

      it "should be purchasable if the user has an expired price rule where they were allowed to purchase" do
        @price_policy = TestPricePolicy.create!(price_group: @price_group,
                                                product: @product,
                                                start_date: Time.zone.now - 7.days,
                                                expire_date: Time.zone.now - 1.day,
                                                can_purchase: true)
        expect(@product).to be_can_purchase(@user_price_group_ids)
      end

      it "should not be purchasable if there is a current rule, but marked as can_purchase = false" do
        @price_policy = TestPricePolicy.create!(price_group: @price_group,
                                                product: @product,
                                                start_date: Time.zone.now - 1.day,
                                                expire_date: Time.zone.now + 7.days,
                                                can_purchase: false)
        expect(@product).not_to be_can_purchase(@user_price_group_ids)
      end

      it "should not be purchasable if the most recent expired policy is marked can_purchase = false" do
        @price_policy = TestPricePolicy.create!(price_group: @price_group,
                                                product: @product,
                                                start_date: Time.zone.now - 7.days,
                                                expire_date: Time.zone.now - 6.days,
                                                can_purchase: true)
        @price_policy2 = TestPricePolicy.create!(price_group: @price_group,
                                                 product: @product,
                                                 start_date: Time.zone.now - 5.days,
                                                 expire_date: Time.zone.now + 4.days,
                                                 can_purchase: false)
        expect(@product).not_to be_can_purchase(@user_price_group_ids)
      end

      it "should be purchasable if the most recent expired policy is can_purchase, but old ones arent" do
        @price_policy = TestPricePolicy.create!(price_group: @price_group,
                                                product: @product,
                                                start_date: Time.zone.now - 7.days,
                                                expire_date: Time.zone.now - 6.days,
                                                can_purchase: false)
        @price_policy2 = TestPricePolicy.create!(price_group: @price_group,
                                                 product: @product,
                                                 start_date: Time.zone.now - 5.days,
                                                 expire_date: Time.zone.now + 4.days,
                                                 can_purchase: true)
        expect(@product).to be_can_purchase(@user_price_group_ids)
      end

      it "should be purchasable if there is a current policy with can_purchase, but a future one that cant" do
        @current_price_policy = TestPricePolicy.create!(price_group: @price_group,
                                                        product: @product,
                                                        start_date: Time.zone.now - 7.days,
                                                        expire_date: Time.zone.now + 1.day,
                                                        can_purchase: true)
        @future_price_policy2 = TestPricePolicy.create!(price_group: @price_group,
                                                        product: @product,
                                                        start_date: Time.zone.now + 2.days,
                                                        expire_date: Time.zone.now + 4.days,
                                                        can_purchase: false)
        expect(@product.current_price_policies).to eq([@current_price_policy])
        expect(@product).to be_can_purchase(@user_price_group_ids)
      end

      it "should not be purchasable if there is a current policy without can_purchase, but a future one that can" do
        @current_price_policy = TestPricePolicy.create!(price_group: @price_group,
                                                        product: @product,
                                                        start_date: Time.zone.now - 7.days,
                                                        expire_date: Time.zone.now + 1.day,
                                                        can_purchase: false)
        @future_price_policy2 = TestPricePolicy.create!(price_group: @price_group,
                                                        product: @product,
                                                        start_date: Time.zone.now + 2.days,
                                                        expire_date: Time.zone.now + 4.days,
                                                        can_purchase: true)
        expect(@product).not_to be_can_purchase(@user_price_group_ids)
      end
      it "should be purchasable if there are no current policies, but two future policies, one of which is purchasable and one is not" do
        expect(@product.current_price_policies).to be_empty
        @price_policy_pg1 = TestPricePolicy.create!(price_group: @price_group,
                                                    product: @product,
                                                    start_date: Time.zone.now + 2.days,
                                                    expire_date: Time.zone.now + 4.days,
                                                    can_purchase: true)
        @price_policy_pg2 = TestPricePolicy.create!(price_group: @price_group2,
                                                    product: @product,
                                                    start_date: Time.zone.now + 2.days,
                                                    expire_date: Time.zone.now + 4.days + 1.second,
                                                    can_purchase: false)
        FactoryGirl.create(:user_price_group_member, user: @user, price_group: @price_group2)
        @user_price_group_ids = @user.reload.price_groups.map(&:id)
        expect(@product).to be_can_purchase(@user_price_group_ids)
      end

      it "should not be purchasable if there are no current policies, and most recent for each group cannot can_purchase" do
        @price_policy_pg1_1 = TestPricePolicy.create!(price_group: @price_group,
                                                      product: @product,
                                                      start_date: Time.zone.now - 7.days,
                                                      expire_date: Time.zone.now - 5.days,
                                                      can_purchase: false)
        @price_policy_pg1_2 = TestPricePolicy.create!(price_group: @price_group,
                                                      product: @product,
                                                      start_date: Time.zone.now - 4.days,
                                                      expire_date: Time.zone.now - 4.days,
                                                      can_purchase: false)

        @price_policy_pg2_1 = TestPricePolicy.create!(price_group: @price_group2,
                                                      product: @product,
                                                      start_date: Time.zone.now - 7.days,
                                                      expire_date: Time.zone.now - 5.days,
                                                      can_purchase: false)
        @price_policy_pg2_2 = TestPricePolicy.create!(price_group: @price_group2,
                                                      product: @product,
                                                      start_date: Time.zone.now - 5.days,
                                                      expire_date: Time.zone.now - 4.days,
                                                      can_purchase: false)
        FactoryGirl.create(:user_price_group_member, user: @user, price_group: @price_group2)
        @user_price_group_ids = @user.reload.price_groups.map(&:id)
        expect(@product).not_to be_can_purchase(@user_price_group_ids)

      end
    end

    describe "accessories" do
      before :each do
        create :accessory
        dup = ProductAccessory.first.dup
        dup.deleted_at = Time.zone.now
        dup.save!
      end

      let(:product_accessory) { ProductAccessory.first.product }

      it "has 1 active accessory" do
        expect(product_accessory.accessories.size).to eq 1
      end

      it "has 1 active product accessory" do
        expect(product_accessory.product_accessories.size).to eq 1
      end
    end

    context '#access_group_for_user' do
      context "with an access group" do
        before :each do
          schedule_rule.product_access_groups = [access_group]
        end

        context "with a user in the access group" do
          before :each do
            product_user.product_access_group = access_group
            product_user.save
          end

          it "returns the access group" do
            expect(product.access_group_for_user(user)).to eq access_group
          end
        end

        context "with a user not in the access group" do
          it "returns no access group" do
            expect(product.access_group_for_user(user)).to be_nil
          end
        end
      end

      it "without an access group" do
        expect(product.access_group_for_user(user)).to be_nil
      end
    end

    describe "#can_be_used_by?" do
      context "when the product requires approval" do
        before { schedule_rule.product_access_groups = [access_group] }

        context "an access list exists for the user" do
          before :each do
            product_user = product_access_group = access_group
            product_user.save
          end

          it "allows access" do
            expect(product.can_be_used_by?(user)).to be true
          end
        end

        context "an access list does not exist for the user" do
          let(:denied_user) { build_stubbed(:user) }

          it "denies access" do
            expect(product.can_be_used_by?(denied_user)).to be false
          end
        end
      end

      context "when the product does not require approval" do
        before { product.update_attribute(:requires_approval, false) }

        it "allows access" do
          expect(product.can_be_used_by?(user)).to be true
        end
      end
    end

    context '#find_product_user' do
      context "when a user is a product user" do
        it "finds the product_user" do
          expect(product.find_product_user(user)).to eq product_user
        end
      end

      context "when a user is not a product user" do
        let(:other_user) { create(:user) }

        it "does not find a product_user" do
          expect(product.find_product_user(other_user)).to be_nil
        end
      end
    end

    context '#has_access_list?' do
      context "when its type supports access groups" do
        context "when it has an access group" do
          before :each do
            product.product_access_groups = [access_group]
          end

          it "has an access list" do
            expect(product.has_access_list?).to be true
          end
        end

        context "when it has no access groups" do
          it "does not have an access list" do
            expect(product.has_access_list?).to be false
          end
        end
      end

      context "when its type does not support access groups" do
        let(:generic_item) { build(:setup_item) }

        it "does not have an access list" do
          expect(generic_item.has_access_list?).to be false
        end
      end
    end

    context "url_name collisions" do
      context "when a product's url_name exists in its facility" do
        let(:new_product) { build(:instrument_requiring_approval, url_name: product.url_name, facility: product.facility) }

        it "is invalid" do
          expect(new_product).to_not be_valid
          expect(new_product.errors.messages).to include :url_name
        end
      end

      context "when a product's url_name exists in another facility" do
        let(:other_facility) { create(:facility) }
        let(:new_product) { build(:instrument_requiring_approval, url_name: "product_name", facility: facility) }

        before :each do
          other_facility.facility_accounts.create(attributes_for(:facility_account))
          create(:instrument_requiring_approval, url_name: "product_name", facility: other_facility)
        end

        it "is valid" do
          expect(new_product).to be_valid
        end
      end
    end
  end

  describe "#training_request_contacts" do
    let(:product) { build(:item, training_request_contacts: contacts) }
    subject(:emails) { product.training_request_contacts.to_a }

    describe "blank" do
      let(:contacts) { "" }
      it { is_expected.to eq [] }
    end

    describe "nil" do
      let(:contacts) { nil }
      it { is_expected.to eq [] }
    end

    describe "a single address" do
      let(:contacts) { "testing@example.com" }
      it { is_expected.to eq ["testing@example.com"] }
      it "is valid" do
        product.valid?
        expect(product.errors).not_to include(:training_request_contacts)
      end
    end

    describe "multiple addresses" do
      let(:contacts) { "testing@example.com, test2@nucore.com" }
      it { is_expected.to eq ["testing@example.com", "test2@nucore.com"] }
      it "is valid" do
        product.valid?
        expect(product.errors).not_to include(:training_request_contacts)
      end
    end

    describe "some extra commas in there" do
      let(:contacts) { "testing@example.com,, ,test2@nucore.com,test-something+other@test.com" }
      it { is_expected.to eq ["testing@example.com", "test2@nucore.com", "test-something+other@test.com"] }
      it "is valid" do
        product.valid?
        expect(product.errors).not_to include(:training_request_contacts)
      end
    end

    describe "invalid emails" do
      let(:contacts) { "valid@tablexi.com, invalid@ " }
      it { is_expected.to eq ["valid@tablexi.com", "invalid@"] }
      it "is invalid" do
        expect(product).to be_invalid
        expect(product.errors).to include(:training_request_contacts)
      end
    end
  end

  describe "#training_request_contacts=" do
    let(:product) { build(:item) }
    let(:contacts) { "testing@example.com,, ,test2@nucore.com," }
    let(:cleaned_contacts) { "testing@example.com, test2@nucore.com" }

    it "cleans the attribute when doing =" do
      product.training_request_contacts = contacts
      expect(product.read_attribute(:training_request_contacts)).to eq(cleaned_contacts)
    end

    it "cleans the attribute when doing assigns_attributes" do
      product.assign_attributes(training_request_contacts: contacts)
      expect(product.read_attribute(:training_request_contacts)).to eq(cleaned_contacts)
    end
  end
end
