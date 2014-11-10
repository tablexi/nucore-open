require 'spec_helper'
require 'timecop'

describe OrderDetail do
  let(:account) { @account }
  let(:facility) { @facility }
  let(:facility_account) { @facility_account }
  let(:instrument) { create(:instrument, facility: facility, facility_account_id: facility_account.id) }
  let(:item) { @item }
  let(:order) { @order }
  let(:order_detail) { @order_detail }
  let(:price_group) { create(:price_group, facility: facility) }
  let(:user) { @user }

  before(:each) do
    Settings.order_details.status_change_hooks = nil
    @facility = create(:facility)
    @facility_account = @facility.facility_accounts.create(attributes_for(:facility_account))
    @user     = create(:user)
    @item     = @facility.items.create(attributes_for(:item, facility_account_id: @facility_account.id))
    @item.should be_valid
    @user_accounts = create_list(:nufs_account, 5, account_users_attributes: account_users_attributes_hash(user: @user))
    @account = @user_accounts.first
    @order    = @user.orders.create(attributes_for(:order, created_by: @user.id, account: @account, facility: @facility))
    @order.should be_valid
    @order_detail = @order.order_details.create(attributes_for(:order_detail).update(product_id: @item.id, account_id: @account.id))
    @order_detail.state.should == 'new'
    @order_detail.version.should == 1
    @order_detail.order_status.should be_nil
  end

  context '#assign_price_policy' do
    before { order_detail.update_attribute(:price_policy_id, nil) }

    context 'when a compatible price policy exists' do
      before :each do
        create(:user_price_group_member, user: user, price_group: price_group)
      end

      let!(:price_policy) do
        item.item_price_policies.create(attributes_for(:item_price_policy,
          unit_cost: 10.00,
          unit_subsidy: 2.00,
          price_group_id: price_group.id,
        ))
      end

      it 'assigns a price policy' do
        expect { order_detail.assign_price_policy }
        .to change { order_detail.price_policy }.from(nil).to(price_policy)
      end

      it 'assigns an actual cost' do
        expect { order_detail.assign_price_policy }
        .to change { order_detail.actual_cost }.from(nil).to(10.00)
      end

      it 'assigns an actual subsidy' do
        expect { order_detail.assign_price_policy }
        .to change { order_detail.actual_subsidy }.from(nil).to(2.00)
      end
    end

    context 'when no compatible price policies exist' do
      it 'it does not assign a price policy' do
        expect { order_detail.assign_price_policy }
        .not_to change { order_detail.price_policy }
      end
    end
  end

  context 'account reassignment' do
    let(:unassociated_account) { build_stubbed(:setup_account) }

    describe '#can_be_assigned_to_account?' do
      it 'may be reassigned to its current account' do
        expect(@order_detail.can_be_assigned_to_account?(@order_detail.account))
          .to be_true
      end

      it "may assign to any of its user's accounts" do
        @user_accounts.each do |account|
          expect(@order_detail.can_be_assigned_to_account?(account)).to be_true
        end
      end
      it 'may not assign to an account its user does not have' do
        expect(@order_detail.can_be_assigned_to_account?(unassociated_account))
          .to be_false
      end
    end

    describe '.reassign_account!' do
      context 'the account is valid for all order_details' do
        it 'reassigns them' do
          @user_accounts.reverse.each do |account|
            expect { OrderDetail.reassign_account!(account, [@order_detail]) }
              .to change{@order_detail.account}.to account
          end
        end
      end
      context 'the account is not valid for all order_details' do
        it 'raises ActiveRecord::RecordInvalid' do
          expect { OrderDetail.reassign_account!(unassociated_account, [@order_detail]) }
            .to raise_error ActiveRecord::RecordInvalid
        end
      end
    end
  end

  context 'bundle' do
    before :each do
      @bundle=create(:bundle, facility_account: @facility_account, facility: @facility)
      @bundle_product=BundleProduct.create!(bundle: @bundle, product: @item, quantity: 1)
      @order_detail.bundle=@bundle
      assert @order_detail.save
    end

    it 'should be bundled' do
      @order_detail.should be_bundled
    end

    it 'should not be bundled' do
      @order_detail.bundle=nil
      assert @order_detail.save
      @order_detail.should_not be_bundled
    end
  end

  it 'should have a created_by' do
    should_not allow_value(nil).for(:created_by)
  end

  it "should have a product" do
    should_not allow_value(nil).for(:product_id)
  end

  it "should have a order" do
    should_not allow_value(nil).for(:order_id)
  end

  it "should have a quantity of at least 1" do
    should_not allow_value(0).for(:quantity)
    should_not allow_value(nil).for(:quantity)
    should allow_value(1).for(:quantity)
  end

  context "update quantity" do
    let(:new_quantity) { order_detail.quantity + 4 }

    context 'with estimated costs' do
      it 're-estimates pricing' do
        expect(order_detail).to receive(:cost_estimated?).and_return true
        expect(order_detail).to receive :assign_estimated_price
        order_detail.quantity = new_quantity
        order_detail.save!
        expect(order_detail.reload.quantity).to eq new_quantity
      end
    end

    context 'with actual costs' do
      it 're-assigns actual pricing' do
        expect(order_detail).to receive(:cost_estimated?).and_return false
        expect(order_detail).to receive(:actual_cost).exactly(2).times.and_return 50
        expect(order_detail).to receive :assign_actual_price
        order_detail.quantity = new_quantity
        order_detail.save!
        expect(order_detail.reload.quantity).to eq new_quantity
      end
    end
  end

  context "assigning estimated costs" do
    context "for reservations" do
      before(:each) do
        @instrument = create(:instrument,
                                            facility: @facility,
                                            reserve_interval: 15,
                                            facility_account_id: @facility_account.id)
        @price_group = create(:price_group, facility: @facility)
        create(:price_group_product, product: @instrument, price_group: @price_group)
        UserPriceGroupMember.create!(price_group: @price_group, user: @user)
        @pp=create(:instrument_price_policy, :product=> @instrument, price_group: @price_group)
        @rule = @instrument.schedule_rules.create(attributes_for(:schedule_rule).merge(start_hour: 0, end_hour: 24))
        @order_detail.reservation = create(:reservation,
                reserve_start_at: Time.now,
                reserve_end_at: Time.now+1.hour,
                :product=> @instrument
              )
        @order_detail.product = @instrument
        @order_detail.save
        assert @order_detail.reservation
        @start_stop = [Time.now, Time.now+1.hour]
      end

      it "should assign_estimated_price" do
        @order_detail.estimated_cost.should be_nil
        # will be the cheapest price policy
        @order_detail.assign_estimated_price
        @order_detail.estimated_cost.should == @pp.estimate_cost_and_subsidy(*@start_stop)[:cost]
      end

      it "should assign_estimated_price_from_policy" do
        @order_detail.estimated_cost.should be_nil
        @order_detail.assign_estimated_price_from_policy(@pp)
        @order_detail.estimated_cost.should == @pp.estimate_cost_and_subsidy(*@start_stop)[:cost]
      end
    end
  end

  context "item purchase validation" do
    before(:each) do
      @account        = create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
      @price_group    = create(:price_group, facility: @facility)
      @pg_user_member = create(:user_price_group_member, user: @user, price_group: @price_group)
      @item_pp        = @item.item_price_policies.create(attributes_for(:item_price_policy, price_group_id: @price_group.id))
      @order_detail.update_attributes(actual_cost: 20, actual_subsidy: 10, price_policy_id: @item_pp.id)
    end

    it "should not be valid if there is no account" do
      @order_detail.update_attributes(account_id: nil)
      @order_detail.valid_for_purchase?.should_not == true
    end

    it "should not be valid if the chart string account does not match the product account"

    context 'needs open account' do
      before :each do
        create(:price_group_product, product: @item, price_group: @price_group, reservation_window: nil)
        define_open_account(@order_detail.product.account, @order_detail.account.account_number)
      end

      it "should be valid for an item purchase with valid attributes" do
        @order_detail.valid_for_purchase?.should == true
      end

      it "should be valid if there is no actual price" do
        @order_detail.update_attributes(actual_cost: nil, actual_subsidy: nil)
        @order_detail.valid_for_purchase?.should == true
      end

      it "should be valid if a price policy is not selected" do
        @order_detail.update_attributes(price_policy_id: nil)
        @order_detail.valid_for_purchase?.should == true
      end

      it "should not be valid if the user is not approved for the product" do
        @item.update_attributes(requires_approval: true)
        @order_detail.reload # reload to update related item
        @order_detail.valid_for_purchase?.should_not == true
        ProductUser.create({product: @item, user: @user, approved_by: @user.id})
        @order_detail.valid_for_purchase?.should == true
      end
    end
  end

  context "service purchase validation" do
     before(:each) do
      @account        = create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
      @price_group    = create(:price_group, facility: @facility)
      @pg_user_member = create(:user_price_group_member, user: @user, price_group: @price_group)
      @order          = @user.orders.create(attributes_for(:order, facility_id: @facility.id, account_id: @account.id, created_by: @user.id))
      @service        = @facility.services.create(attributes_for(:service, facility_account_id: @facility_account.id))
      @service_pp     = @service.service_price_policies.create(attributes_for(:service_price_policy, price_group_id: @price_group.id))
      @order_detail   = @order.order_details.create(attributes_for(:order_detail).update(product_id: @service.id, account_id: @account.id))
      @order_detail.update_attributes(actual_cost: 20, actual_subsidy: 10, price_policy_id: @service_pp.id)
    end

    ## TODO will need to re-write to check for file uploads
    it 'should validate for a service with no file template upload' do
      @order_detail.valid_service_meta?.should be true
    end

    it 'should not validate_extras for a service file template upload with no template results' do
      # add service file template
      @file1      = "#{Rails.root}/spec/files/template1.txt"
      @template1  = @service.stored_files.create(name: "Template 1", file: File.open(@file1), file_type: "template",
                                                 created_by: @user.id)
      @order_detail.valid_service_meta?.should be false
    end

    it 'should validate_extras for a service file template upload with template results' do
      # add service file template
      @file1      = "#{Rails.root}/spec/files/template1.txt"
      @template1  = @service.stored_files.create(name: "Template 1", file: File.open(@file1), file_type: "template",
                                                 created_by: @user)
      # add results for a specific order detail
      @results1   = @service.stored_files.create(name: "Results 1", file: File.open(@file1), file_type: "template_result",
                                                 order_detail: @order_detail, created_by: @user)
      @order_detail.valid_service_meta?.should be true
    end
  end

  context 'instrument' do
    context 'where the account has a price group, but the user does not' do
      let(:reservation) { create(:setup_reservation) }
      let(:order_detail) { reservation.order_detail }
      let(:price_group) { create(:price_group, facility: @facility) }
      before :each do
        create(:price_group_product, product: order_detail.product, price_group: price_group)
        create(:instrument_price_policy, product: order_detail.product, price_group: price_group)
        order_detail.user.stub(:price_groups).and_return([])
        order_detail.account.stub(:price_groups).and_return([price_group])
      end

      it 'allows purchase' do
        order_detail.should be_valid_for_purchase
      end
    end

#    before :each do
#      @price_group    = create(:price_group, facility: @facility)
#      @pg_user_member = create(:user_price_group_member, user: @user, price_group: @price_group)
#      @order          = @user.orders.create(attributes_for(:order, facility_id: @facility.id, account_id: @account.id, created_by: @user.id))
#      @instrument     = @facility.instruments.create(attributes_for(:instrument, facility_account_id: @facility_account.id))
#      @order_detail   = @order.order_details.create(attributes_for(:order_detail).update(product_id: @instrument.id, account_id: @account.id))
#    end


    context 'problem orders' do

#      before :each do
#        @rule           = @instrument.schedule_rules.create(attributes_for(:schedule_rule).merge(start_hour: 0, end_hour: 17))
#        @instrument_pp  = @instrument.instrument_price_policies.create(attributes_for(:instrument_price_policy, price_group_id: @price_group.id))
#        @reservation    = @instrument.reservations.create(reserve_start_date: Date.today+1.day, reserve_start_hour: 10,
#                                                          reserve_start_min: 0, reserve_start_meridian: 'am',
#                                                          duration_value: 60, duration_unit: 'minutes')
#
#        @order_detail.reservation=@reservation
#        define_open_account(@order_detail.product.account, @order_detail.account.account_number)
#        create(:price_group_product, product: @instrument, price_group: @price_group)
#
#        @order_detail.to_inprocess!
#        @order_detail.to_complete!
#      end


      # The setup for instrument order tests is absolutely painful...
      it 'should test that an order with no actual start date is a problem'
      it 'should test that an order with no actual end date is a problem'
      it 'should test that an order with actuals is not a problem'

    end

    context "instrument purchase validation" do
      it "should validate for a valid instrument with reservation"
      it "should not be valid if an instrument reservation is not valid"
      it "should not be valid if there is no estimated or actual price"
    end
  end

  describe "#problem_order?" do
    shared_examples_for "it is complete" do
      it "is complete" do
        expect(order_detail.state).to eq "complete"
        expect(order_detail).to be_complete
      end
    end

    shared_examples_for "it is a problem order" do
      it "is a problem order" do
        expect(order_detail).to be_problem_order
      end
    end

    shared_examples_for "it is not a problem order" do
      it "is not a problem order" do
        expect(order_detail).not_to be_problem_order
      end
    end

    context "with instruments" do
      let(:instruments) do
        create_list(:instrument, 4, facility_account: facility_account, facility: facility)
      end

      let(:instrument_with_actuals) { instruments[0] }
      let(:instrument_with_actuals_and_price_policy) { instruments[1] }
      let(:instrument_without_actuals) { instruments[2] }
      let(:instrument_without_price_policy) { instruments[3] }

      let(:order) do
        create(:order,
          facility: facility,
          user: user,
          created_by: user.id,
          account: account,
          ordered_at: Time.zone.now,
        )
      end

      let(:order_details) do
        instruments.map do |instrument|
          create(:order_detail, order: order, product: instrument)
        end
      end

      let(:order_detail_without_actuals) { order_details[0] }
      let(:order_detail_with_actuals) { order_details[1] }
      let(:order_detail_with_actuals_and_price_policy) { order_details[2] }
      let(:order_detail_without_price_policy) { order_details[3] }

      let(:reservation_for_instrument_with_actuals_and_price_policy) do
        create(:reservation,
          order_detail: order_detail_with_actuals_and_price_policy,
          product: instrument_with_actuals_and_price_policy,
        )
      end

      def create_price_policy(params)
        create(:instrument_price_policy, { price_group: user.price_groups.first }.merge(params))
      end

      before :each do
        instrument_without_actuals.relay.destroy

        instruments.each do |instrument|
          create(:schedule_rule, instrument: instrument)
          instrument.reload
        end

        create_price_policy(product: instrument_without_actuals)
        create_price_policy(product: instrument_with_actuals, usage_rate: 1)
        create_price_policy(product: instrument_with_actuals_and_price_policy, usage_rate: 1)

        create(:reservation,
          product: instrument_without_actuals,
          order_detail: order_detail_without_actuals,
        )
        create(:reservation,
          product: instrument_with_actuals,
          order_detail: order_detail_with_actuals,
        )

        create(:reservation,
          product: instrument_with_actuals_and_price_policy,
          reserve_start_at: reservation_for_instrument_with_actuals_and_price_policy.reserve_start_at + 1.hour,
          duration_mins: 60,
          order_detail: order_detail_without_price_policy,
        )

        Timecop.travel(2.days.from_now) do
          order_details.each do |order_detail|
            order_detail.change_status!(OrderStatus.find_by_name("In Process"))
            order_detail.change_status!(OrderStatus.find_by_name("Complete"))
            order_detail.reload
          end
        end
      end

      context "with an order_detail for an instrument" do
        context "with a price policy not requiring actuals" do
          let(:order_detail) { order_detail_without_actuals }

          it_behaves_like "it is complete"
          it_behaves_like "it is not a problem order"
        end

        context "with a price policy requiring actuals" do
          let(:order_detail) { order_detail_with_actuals }

          it_behaves_like "it is complete"
          it_behaves_like "it is a problem order"

          context "and has a reservation_rate" do
            let(:order_detail) { order_detail_with_actuals_and_price_policy }

            it_behaves_like "it is complete"
            it_behaves_like "it is a problem order"
          end
        end

        context "with no price policy" do
          let(:order_detail) { order_detail_without_price_policy }

          it_behaves_like "it is complete"
          it_behaves_like "it is a problem order"

          context "when a price policy is assigned" do
            let!(:price_policy) do
              create_price_policy(product: order_detail.product)
            end

            before :each do
              order_detail.reservation.assign_actuals_off_reserve
              order_detail.assign_price_policy
              order_detail.save!
            end

            it "has a price policy" do
              expect(order_detail.price_policy).to eq price_policy
            end

            it_behaves_like "it is not a problem order"

            it "has its fulfilled_at timestamp set to its reservation's end_at" do
              expect(order_detail.fulfilled_at)
                .to eq order_detail.reservation.reserve_end_at
            end
          end
        end
      end
    end

    shared_examples_for "a product without reservations" do
      subject(:order_detail) do
        create(:order_detail, order: order, product: product)
      end

      context "with no price policy" do
        before :each do
          Timecop.travel(2.days.from_now) do
            order_detail.change_status!(OrderStatus.find_by_name("In Process"))
            order_detail.change_status!(OrderStatus.find_by_name("Complete"))
            order_detail.reload
          end
        end

        it_behaves_like "it is a problem order"

        context "when adding a compatible price policy" do
          let!(:price_policy) do
            create(price_policy_type,
              price_group: user.price_groups.first,
              product: product,
            )
          end

          def assign_price_policy
            order_detail.assign_price_policy
            order_detail.save!
          end

          it "does not update fulfilled_at on resolution" do
            expect { assign_price_policy }
              .not_to change { order_detail.fulfilled_at }
          end

          context "when assigning a price policy" do
            before { assign_price_policy }

            it_behaves_like "it is not a problem order"
          end
        end
      end
    end

    context "with an item" do
      let(:product) { create(:setup_item, facility: facility) }
      let(:price_policy_type) { :item_price_policy }

      it_behaves_like "a product without reservations"
    end

    context "with a service" do
      let(:product) { create(:setup_service, facility: facility) }
      let(:price_policy_type) { :service_price_policy }

      it_behaves_like "a product without reservations"
    end
  end

  context "state management" do
    it "should not allow transition from 'new' to 'invoiced'" do
      @order_detail.invoice! rescue nil
      @order_detail.state.should == 'new'
      @order_detail.version.should == 1
    end

    it "should allow anyone to transition from 'new' to 'inprocess', increment version" do
      @order_detail.to_inprocess!
      @order_detail.state.should == 'inprocess'
      @order_detail.version.should == 2
    end


    context 'needs price policy' do

      before :each do
        @price_group3 = create(:price_group, facility: @facility)
        UserPriceGroupMember.create!(price_group: @price_group3, user: @user)
        create(:price_group_product, product: @item, price_group: @price_group3, reservation_window: nil)
        @order_detail.reload
      end


      it 'should assign a price policy' do
        pp=create(:item_price_policy, product: @item, price_group: @price_group3)
        @order_detail.price_policy.should be_nil
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.state.should == 'complete'
        @order_detail.price_policy.should == pp
        @order_detail.should_not be_cost_estimated
        @order_detail.should_not be_problem_order
        @order_detail.fulfilled_at.should_not be_nil

        costs=pp.calculate_cost_and_subsidy(@order_detail.quantity)
        @order_detail.actual_cost.should == costs[:cost]
        @order_detail.actual_subsidy.should == costs[:subsidy]
      end


      it 'should not assign a price policy' do
        @order_detail.price_policy.should be_nil
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.state.should == 'complete'
        @order_detail.price_policy.should be_nil
        @order_detail.should be_problem_order
      end

      it "should transition to canceled" do
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.to_canceled!
        expect(@order_detail.state).to eq 'canceled'
        @order_detail.version.should == 4
      end

      it "should not transition to canceled from reconciled" do
        create(:item_price_policy, product: @item, price_group: @price_group3)
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.to_reconciled!
        expect { @order_detail.to_canceled! }.to raise_exception AASM::InvalidTransition
        @order_detail.state.should == 'reconciled'
        @order_detail.version.should == 4
      end

      it "should not transition to canceled if part of journal" do
        journal=create(:journal, facility: @facility, reference: 'xyz', created_by: @user.id, journal_date: Time.zone.now)
        @order_detail.update_attribute :journal_id, journal.id
        @order_detail.reload.journal.should == journal
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.to_canceled!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 4
      end

      context "transitioning to canceled when statemented" do
        let(:statement) { create(:statement, facility: facility, created_by: user.id, account: account) }

        before :each do
          order_detail.update_attribute :statement_id, statement.id
          order_detail.reload
          order_detail.to_inprocess!
          order_detail.to_complete!
          order_detail.update_attributes(actual_cost: 20, actual_subsidy: 10)
          expect(order_detail.statement).to be_present
          expect(order_detail.actual_total).to be_present
        end

        context 'when not reconciled' do
          it 'should transition to canceled' do
            expect { order_detail.to_canceled! }.not_to raise_error
          end
        end

        context 'when reconciled' do
          before :each do
            order_detail.to_reconciled!
          end

          it 'should not transition to canceled' do
            expect { order_detail.to_canceled! }.to raise_exception AASM::InvalidTransition
          end
        end
      end

      it "should transition to reconciled" do
        create(:item_price_policy, product: @item, price_group: @price_group3)
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 3
        @order_detail.to_reconciled!
        @order_detail.state.should == 'reconciled'
        @order_detail.version.should == 4
      end


      it "should not transition to reconciled if there are no actual costs" do
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 3
        @order_detail.to_reconciled!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 3
      end

    end
  end

  context 'statement' do
    before :each do
      @statement=create(:statement, facility: @facility, created_by: @user.id, account: @account)
    end

    it { should allow_value(nil).for(:statement) }
    it { should allow_value(@statement).for(:statement) }
  end

  context 'journal' do
    before :each do
      @journal=create(:journal, facility: @facility, reference: 'xyz', created_by: @user.id, journal_date: Time.zone.now)
    end

    it { should allow_value(nil).for(:journal) }
    it { should allow_value(@journal).for(:journal) }
  end

  context 'date attributes' do
    [ :fulfilled_at, :reviewed_at ].each do |attr|
      it { should allow_value(nil).for(attr) }
      it { should allow_value(Time.zone.now).for(attr) }
    end
  end

  it "should include ids in description" do
    desc=@order_detail.to_s
    desc.should match(/#{@order_detail.id}/)
    desc.should match(/#{@order_detail.order.id}/)
  end

  context 'is_in_dispute?' do
    it 'should be in dispute' do
      @order_detail.dispute_at=Time.zone.now
      @order_detail.dispute_resolved_at=nil
      @order_detail.should be_in_dispute
    end


    it 'should not be in dispute if dispute_at is nil' do
      @order_detail.dispute_at=nil
      @order_detail.dispute_resolved_at="all good"
      @order_detail.should_not be_in_dispute
    end


    it 'should not be in dispute if dispute_resolved_at is not nil' do
      @order_detail.dispute_at=Time.zone.now
      @order_detail.dispute_resolved_at=Time.zone.now+1.day
      @order_detail.should_not be_in_dispute
    end


    it 'should not be in dispute if order detail is canceled' do
      @order_detail.to_canceled!
      @order_detail.dispute_at=Time.zone.now
      @order_detail.dispute_resolved_at=nil
      @order_detail.should_not be_in_dispute
    end
  end

  context "can_dispute?" do
    before :each do
      @order_detail.to_complete
      @order_detail.reviewed_at = 1.day.from_now
      @order_detail.save

      @order_detail2 = @order.order_details.create(attributes_for(:order_detail).update(product_id: @item.id, account_id: @account.id))
      @order_detail2.to_complete
      @order_detail2.reviewed_at = 1.day.ago
      @order_detail2.save!
    end

    it 'should not be disputable if its not complete' do
      @order_detail3 = @order.order_details.create(attributes_for(:order_detail).update(product_id: @item.id, account_id: @account.id))
      @order_detail3.should_not be_can_dispute
    end
    it 'should not be in dispute if the review date has passed' do
      @order_detail.should be_can_dispute
      @order_detail2.should_not be_can_dispute
    end

    it "should not be in dispute if it's already been disputed" do
      @order_detail.dispute_at = 1.hour.ago
      @order_detail.dispute_reason = "because"
      @order_detail.save!
      @order_detail.should_not be_can_dispute
    end
  end

  context 'review period' do
    after :each do
      Settings.reload!
    end
    context '7 day' do
      before :each do
        Settings.billing.review_period = 7.days
      end
      it 'should not have a reviewed time' do
        @order_detail.to_complete
        @order_detail.reviewed_at.should be_nil
      end
    end
    context 'zero day' do
      before :each do
        Settings.billing.review_period = 0.days
      end
      it 'should set reviewed_at to now' do
        @order_detail.to_complete
        @order_detail.reviewed_at.should < Time.zone.now
      end
    end
  end

  context 'named scopes' do
    before :each do
      @order.facility=@facility
      assert @order.save

      # extra facility records to make sure we scope properly
      @facility2 = create(:facility)
      @facility_account2 = @facility2.facility_accounts.create(attributes_for(:facility_account))
      @user2     = create(:user)
      @item2     = @facility2.items.create(attributes_for(:item, facility_account_id: @facility_account2.id))
      @account2  = create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user2))
      @order2    = @user2.orders.create(attributes_for(:order, created_by: @user2.id, facility: @facility2))
      @order_detail2 = @order2.order_details.create(attributes_for(:order_detail).update(product_id: @item2.id, account_id: @account2.id))
    end

    it 'should give recent order details of given facility only' do
      ods=OrderDetail.facility_recent(@facility)
      ods.size.should == 1
      ods.first.should == @order_detail
    end

    it 'should give all order details for a facility' do
      ods=OrderDetail.for_facility(@facility)
      ods.size.should == 1
      ods.first.should == @order_detail
    end


    context 'reservations' do
      before :each do
        @now=Time.zone.now
        setup_reservation @facility, @facility_account, @account, @user
      end


      it 'should be upcoming' do
        start_time=@now+2.days
        place_reservation @facility, @order_detail, start_time, { reserve_end_at: start_time+1.hour }
        upcoming=OrderDetail.upcoming_reservations.all
        upcoming.size.should == 1
        upcoming[0].should == @order_detail
      end


      it 'should not be upcoming because reserve_end_at is in the past' do
        start_time=@now-2.days
        place_reservation @facility, @order_detail, start_time, { reserve_end_at: start_time+1.hour }
        OrderDetail.upcoming_reservations.all.should be_blank
      end


      it 'should not be upcoming because actual_start_at exists' do
        start_time=@now+2.days
        place_reservation @facility, @order_detail, start_time, { reserve_end_at: start_time+1.hour, actual_start_at: start_time }
        OrderDetail.upcoming_reservations.all.should be_blank
      end


      it 'should be in progress' do
        place_reservation @facility, @order_detail, @now, { actual_start_at: @now }
        upcoming=OrderDetail.in_progress_reservations.all
        upcoming.size.should == 1
        upcoming[0].should == @order_detail
      end


      it 'should not be in progress because actual_start_at missing' do
        place_reservation @facility, @order_detail, @now
        OrderDetail.in_progress_reservations.all.should be_empty
      end


      it 'should not be in progress because actual_end_at exists' do
        start_time=@now-3.hour
        place_reservation @facility, @order_detail, start_time, { actual_start_at: start_time, actual_end_at: start_time+1.hour }
        OrderDetail.in_progress_reservations.all.should be_empty
      end
    end

    context 'needs statement' do

      before :each do
        @statement = Statement.create({facility: @facility, created_by: 1, account: @account})
        @order_detail.update_attributes(statement: @statement, reviewed_at: (Time.zone.now-1.day))
        @statement2 = Statement.create({facility: @facility2, created_by: 1, account: @account})
        @order_detail2.statement=@statement2
        assert @order_detail2.save
      end

      it 'should give all order details with statements for a facility' do
        ods=OrderDetail.statemented(@facility)
        ods.size.should == 1
        ods.first.should == @order_detail
      end

      it 'should give finalized order details of given facility only' do
        ods=OrderDetail.finalized(@facility)
        ods.size.should == 1
        ods.first.should == @order_detail
      end

    end

    describe 'action_in_date_range' do
      it 'should raise an error for bad action' do
        expect { OrderDetail.action_in_date_range(:random_action, nil, nil) }.to raise_error(ArgumentError)
      end

      context 'journaled_or_statemented' do
        before :each do
          @journal=create(:journal, facility: @facility, reference: 'xyz', created_by: @user.id, journal_date: 2.day.ago)
          @statement=create(:statement, facility: @facility, created_by: @user.id, account: @account, created_at: 1.day.ago)
          @order_detail.to_complete!
          @order_detail2.to_complete!
          @order_detail.update_attribute :journal_id, @journal.id
          @order_detail2.update_attribute :statement_id, @statement.id
        end

        it 'should return nothing when searching wrong date range' do
          OrderDetail.action_in_date_range(:journal_or_statement_date, 7.days.ago, 6.days.ago).should be_empty
        end

        it 'should work for journal date' do
          OrderDetail.action_in_date_range(:journal_date, 3.days.ago, 1.day.ago).should == [@order_detail]
        end

        it 'should return both statemented and journaled' do
          OrderDetail.action_in_date_range(:journal_or_statement_date, 3.days.ago, Time.zone.now).should =~ [@order_detail, @order_detail2]
        end
      end
    end
  end

  context 'ordered_on_behalf_of?' do
    it 'should return true if the associated order was ordered by someone else' do
      @user2 = create(:user)
      @order_detail.order.update_attributes(created_by_user: @user2)
      @order_detail.reload.should be_ordered_on_behalf_of
    end
    it 'should return false if the associated order was not ordered on behalf of' do
      user = @order_detail.order.user
      @order_detail.order.update_attributes(created_by_user: user)
      @order_detail.reload
      @order_detail.reload.should_not be_ordered_on_behalf_of
    end
  end

  context 'ordered_or_reserved_in_range' do
    before :each do
      ignore_order_detail_account_validations
      @user = create(:user)
      @od_yesterday = place_product_order(@user, @facility, @item, @account)
      @od_yesterday.order.update_attributes(ordered_at: (Time.zone.now - 1.day))

      @od_tomorrow = place_product_order(@user, @facility, @item, @account)
      @od_tomorrow.order.update_attributes(ordered_at: (Time.zone.now + 1.day))

      @od_today = place_product_order(@user, @facility, @item, @account)

      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument=create(:instrument,
                                      facility: @facility,
                                      facility_account: @facility_account,
                                      min_reserve_mins: 60,
                                      max_reserve_mins: 60)

      # all reservations get placed in today
      @reservation_yesterday = place_reservation_for_instrument(@user, @instrument, @account, Time.zone.now - 1.day)
      @reservation_tomorrow = place_reservation_for_instrument(@user, @instrument, @account, Time.zone.now + 1.day)
      @reservation_today = place_reservation_for_instrument(@user, @instrument, @account, Time.zone.now)
    end

    it "should only return the reservations and the orders from today and tomorrow" do
      result = OrderDetail.ordered_or_reserved_in_range(Time.zone.now, nil)
      result.should contain_all [@od_today, @od_tomorrow, @reservation_today.order_detail, @reservation_tomorrow.order_detail]
    end

    it "should only return the reservations and the orders from today and yesterday" do
      result = OrderDetail.ordered_or_reserved_in_range(nil, Time.zone.now)
      result.should contain_all [@od_yesterday, @od_today, @reservation_yesterday.order_detail, @reservation_today.order_detail]
    end

    it "should only return the order detail and the reservation from today" do
      result = OrderDetail.ordered_or_reserved_in_range(Time.zone.now, Time.zone.now)
      result.should contain_all [@od_today, @reservation_today.order_detail]
    end
  end

  context '#cancel_reservation' do
    let(:statement) { create(:statement, facility: facility, created_by: user.id, account: account) }

    before :each do
      start_date = Time.zone.now + 1.day
      setup_reservation facility, facility_account, account, user
      place_reservation facility, order_detail, start_date
      create :user_price_group_member, user_id: user.id, price_group_id: @price_group.id
      order_detail.update_attribute :statement_id, statement.id
    end

    shared_context 'instrument minimum cancel hours' do
      before :each do
        @instrument.update_attribute :min_cancel_hours, 25
        order_detail.reload
      end
    end

    shared_examples 'it was removed from its statement' do
      it 'should be removed from the statement' do
        expect(original_statement.order_details).not_to include(order_detail)
        expect(order_detail.statement).to be_blank
      end

      it 'should have no #statement_date' do
        expect(order_detail.statement_date).to be_blank
      end
    end

    shared_examples 'a cancellation without fees' do
      it_should_behave_like 'it was removed from its statement'

      it 'canceled its reservation' do
        @reservation.reload
        expect(@reservation.canceled_by).to eq user.id
        expect(@reservation.canceled_at).to be_present
      end

      it 'is in a canceled state' do
        expect(order_detail.state).to eq 'canceled'
      end

      it 'has no actual cost' do
        expect(order_detail.actual_cost).to be_blank
      end

      it 'has no actual subsidy' do
        expect(order_detail.actual_subsidy).to be_blank
      end
    end

    context 'with a cancellation fee' do
      shared_examples 'a cancellation with fees applied' do

        it 'should remain on its statement' do
          expect(order_detail.statement).to eq original_statement
        end

        it 'is in "complete" state' do
          expect(order_detail.state).to eq 'complete'
        end

        it 'has its cancellation cost applied to its statement' do
          expect(order_detail.actual_cost)
            .to eq order_detail.price_policy.cancellation_cost
        end

        it 'has no actual subsidy' do
          expect(order_detail.actual_subsidy).to eq 0
        end
      end

      before :each do
        set_cancellation_cost_for_all_policies 5.0
      end

      context 'as admin' do
        let!(:original_statement) { order_detail.statement }

        context 'when waiving the cancellation fee' do
          before :each do
            order_detail.cancel_reservation(user, OrderStatus.canceled.first, true, false)
            order_detail.reload
            @reservation.reload
          end

          it_should_behave_like 'a cancellation without fees'
        end

        context 'when applying the cancellation fee' do
          include_context 'instrument minimum cancel hours'

          before :each do
            order_detail.cancel_reservation(user, OrderStatus.canceled.first, true, true)
            order_detail.reload
            @reservation.reload
          end

          it_should_behave_like 'a cancellation with fees applied'
        end
      end

      context 'as user' do
        include_context 'instrument minimum cancel hours'

        context 'the reservation was already canceled' do
          it 'should not cancel' do
            @reservation.update_attribute :canceled_at, Time.zone.now
            expect(order_detail.cancel_reservation(user)).to be_false
          end
        end

        context 'when applying the cancellation fee' do
          let!(:original_statement) { order_detail.statement }

          before :each do
            order_detail.cancel_reservation(user)
          end

          it_should_behave_like 'a cancellation with fees applied'
        end
      end
    end

    context 'without a cancellation fee' do
      let!(:original_statement) { order_detail.statement }

      include_context 'instrument minimum cancel hours'

      before :each do
        set_cancellation_cost_for_all_policies 0
      end

      context 'as admin' do
        before :each do
          order_detail.cancel_reservation(user, OrderStatus.canceled.first, true, true)
        end

        it_should_behave_like 'a cancellation without fees'
      end

      context 'as user' do
        before :each do
          order_detail.cancel_reservation(user, OrderStatus.canceled.first, false, true)
        end

        it_should_behave_like 'a cancellation without fees'
      end
    end
  end

  context '#cancellation_fee' do
    shared_examples_for 'it charges a cancellation fee' do
      it 'has a cancellation fee' do
        expect(order_detail.cancellation_fee).to be > 0
      end
    end

    shared_examples_for 'it charges no cancellation fee' do
      it 'has no cancellation fee' do
        expect(order_detail.cancellation_fee).to eq 0
      end
    end

    shared_examples_for 'it charges cancellation fees appropriately' do
      context 'with a limited no-fee cancellation period' do
        before :each do
          instrument.update_attribute(:min_cancel_hours, 2)
          order_detail.reload
          reservation.update_attribute(:canceled_at, Time.zone.now)
        end

        context 'when in the no-fee period' do
          it_behaves_like 'it charges no cancellation fee'
        end

        context 'when after the time when the cancellation fee applies' do
          before :each do
            @current_time = Time.now
            Timecop.freeze(3.hours.from_now)
            reservation.update_attribute(:canceled_at, Time.zone.now)
          end

          after { Timecop.freeze(@current_time) }

          it_behaves_like 'it charges a cancellation fee'
        end
      end

      context 'without minimum cancellation hours' do
        before { instrument.update_attribute(:min_cancel_hours, 0) }

        it_behaves_like 'it charges no cancellation fee'
      end
    end

    shared_examples_for 'it charges for overage' do
      let!(:price_policy) { instrument_overage_price_policy }

      it_should_behave_like 'it charges cancellation fees appropriately'
    end

    shared_examples_for 'it charges for reservation' do
      let!(:price_policy)  { instrument_reservation_price_policy }

      context 'when the reservation has been canceled' do
        before { reservation.update_attribute(:canceled_at, Time.zone.now) }

        it_should_behave_like 'it charges cancellation fees appropriately'
      end

      context 'when the reservation has been completed' do
        before :each do
          reservation.update_attributes(
            actual_start_at: 1.hour.ago,
            actual_end_at: Time.zone.now,
          )
        end

        it_should_behave_like 'it charges cancellation fees appropriately'
      end
    end

    shared_examples_for 'it charges for usage' do
      let!(:price_policy) { instrument_usage_price_policy }

      it_should_behave_like 'it charges cancellation fees appropriately'
    end

    shared_examples_for 'it charges for overage, reservation, and usage' do
      it_behaves_like 'it charges for overage'
      it_behaves_like 'it charges for reservation'
      it_behaves_like 'it charges for usage'
    end

    let(:instrument_overage_price_policy) do
      create(:instrument_overage_price_policy,
        cancellation_cost: 100,
        price_group: price_group,
        product: instrument,
      )
    end

    let(:instrument_reservation_price_policy) do
      create(:instrument_price_policy,
        cancellation_cost: 100,
        price_group: price_group,
        product: instrument,
      )
    end

    let(:instrument_usage_price_policy) do
      create(:instrument_usage_price_policy,
        cancellation_cost: 100,
        price_group: price_group,
        product: instrument,
      )
    end

    let(:reservation) do
      create(:reservation,
        reserve_start_at: 4.hours.from_now,
        reserve_end_at: 5.hours.from_now,
        product: instrument,
      )
    end

    before :each do
      order_detail.update_attribute(:product_id, instrument.id)
      order_detail.reservation = reservation
      create(:user_price_group_member, user: user, price_group: price_group)
      order_detail.reload
    end

    context 'with a price policy' do
      before :each do
        order_detail.update_attribute(:price_policy_id, price_policy.id)
      end

      it_behaves_like 'it charges for overage, reservation, and usage'
    end

    context 'without a price policy' do
      context 'when no compatible price policies exist' do
        it_behaves_like 'it charges no cancellation fee'
      end

      context 'when a compatible price policy exists' do
        it_behaves_like 'it charges for overage, reservation, and usage'
      end
    end
  end

  context '.account_unreconciled' do
    context 'where the account is a NufsAccount' do
      let(:journal) { create(:journal, facility: facility, reference: 'xyz', created_by: user.id, journal_date: Time.zone.now) }
      let(:unreconciled_order_details) { OrderDetail.account_unreconciled(facility, account) }

      before :each do
        @order_details = 3.times.map do
          order_detail = order.order_details.create(attributes_for(:order_detail)
            .update(product_id: item.id, account_id: account.id, journal_id: journal.id))
          order_detail.change_status!(OrderStatus.find_by_name('In Process'))
          order_detail.change_status!(OrderStatus.find_by_name('Complete'))
          order_detail.reload
        end
      end

      it 'should find order details ready to be reconciled' do
        expect(unreconciled_order_details.to_a).to eq @order_details.to_a
      end
    end
  end

  context '#update_order_status!' do
    context 'when setting order status to Canceled' do

      def cancel_order_detail(options)
        order_detail.update_order_status!(user, OrderStatus.canceled.first, options)
      end

      context 'is statemented' do
        let(:statement) { create(:statement, facility: facility, created_by: user.id, account: account) }

        before :each do
          order_detail.update_attribute :statement_id, statement.id
        end

        context 'product has a reservation' do
          before :each do
            instrument.update_attribute :min_cancel_hours, 25
            order_detail.reservation = create(:reservation, product: instrument)
            order_detail.product = instrument.reload
            order_detail.price_policy = instrument.instrument_price_policies
              .create(attributes_for(:instrument_price_policy, price_group_id: price_group.id))
            order_detail.save!
          end

          context 'has a cancellation fee' do
            before :each do
              set_cancellation_cost_for_all_policies 5.0
              order_detail.price_policy.reload
            end

            context 'admin waives the fee' do
              it 'is removed from its statement' do
                expect { cancel_order_detail(admin: true, apply_cancel_fee: false) }
                  .to change{order_detail.statement}.from(statement).to(nil)
              end
            end

            context 'admin does not waive the fee' do
              it 'remains on its statement' do
                expect { cancel_order_detail(admin: true, apply_cancel_fee: true) }
                  .not_to change{order_detail.statement}
              end
            end
          end

          context 'has no cancellation fee' do
            before :each do
              set_cancellation_cost_for_all_policies 0
            end

            it 'is removed from its statement' do
              expect { cancel_order_detail(admin: true, apply_cancel_fee: true) }
                .to change{order_detail.statement}.from(statement).to(nil)
            end
          end
        end

        context 'product has no reservation' do
          before :each do
            order_detail.price_policy = item.item_price_policies
              .create(attributes_for(:item_price_policy, price_group_id: price_group.id))
            order_detail.product = item
            order_detail.save!
          end

          it 'has no cancellation fee' do
            expect(order_detail.cancellation_fee).to eq 0
          end

          it 'is removed from its statement' do
            expect { cancel_order_detail(admin: true, apply_cancel_fee: true) }
              .to change{order_detail.statement}.from(statement).to(nil)
          end
        end
      end
    end
  end

  context 'OrderDetailObserver' do
    context 'after_destroy' do
      it 'should not destroy order if order is not a merge and there are no more details' do
        @order_detail.destroy
        @order.reload.should_not be_frozen
        @order.order_details.should be_empty
      end

      context 'as merge order' do
        before(:each) { setup_merge_order }

        it 'should destroy merge order when its last detail is killed' do
          @order_detail.destroy
          assert_raise(ActiveRecord::RecordNotFound){ Order.find @order.id }
        end

        it 'should not destroy merge order when there are other details' do
          @service=@facility.services.create(attributes_for(:service, facility_account_id: @facility_account.id))
          Service.any_instance.stub(:active_survey?).and_return(true)
          @order.order_details.create(attributes_for(:order_detail, product_id: @service.id, account_id: @account.id))
          @order.order_details.size.should == 2
          @order_detail.destroy
          @order.reload.should_not be_frozen
          @order.order_details.size.should == 1
        end
      end
    end

    context 'before_save/after_save merge order handling' do
      before(:each) { setup_merge_order }

      context 'item' do
        it 'should update order_id and delete merge order' do
          assert @order_detail.save
          @order_detail.reload.order.should == @merge_to_order
          assert_raise(ActiveRecord::RecordNotFound) { Order.find @order.id }
        end

        it 'should not affect non merge orders' do
          assert @order_detail.save
          @order_detail.reload.order.should == @merge_to_order
          assert @order_detail.reload.save
          @order_detail.reload.order.should == @merge_to_order
        end

        it 'should update order_id but not delete merge order when there is another detail' do
          @service=@facility.services.create(attributes_for(:service, facility_account_id: @facility_account.id))
          Service.any_instance.stub(:active_survey?).and_return(true)
          @order.order_details.create(attributes_for(:order_detail, product_id: @service.id, account_id: @account.id))
          assert @order_detail.reload.save
          @order_detail.reload.order.should == @merge_to_order
          assert_nothing_raised do
            @order.reload.order_details.size.should == 1
          end
        end

        context 'notifications' do

          it 'should be a NotificationSubject' do
            @order_detail.should be_is_a(NotificationSubject)
          end

          it 'should delete merge notification after merge' do
            MergeNotification.create_for! @user, @order_detail
            assert @order_detail.save
            MergeNotification.count.should == 0
          end

          it 'should delete merge notification on destroy' do
            MergeNotification.create_for! @user, @order_detail
            @order_detail.destroy
            @order_detail.should be_frozen
            MergeNotification.count.should == 0
          end

          it 'should produce a notice' do
            @order_detail.to_notice(MergeNotification).should_not be_blank
          end

        end
      end

      context 'service' do
        before :each do
          @service=@facility.services.create(attributes_for(:service, facility_account_id: @facility_account.id))
          Service.any_instance.stub(:active_survey?).and_return(true)
          @service_order_detail=@order.order_details.create(attributes_for(:order_detail, product_id: @service.id, account_id: @account.id))
        end

        it 'should not update order_id if there is an incomplete active survey' do
          assert @service_order_detail.save
          @service_order_detail.reload.order.should == @order
          @order.reload.should be_to_be_merged
        end

        it 'should not affect non merge orders' do
          OrderDetail.any_instance.stub(:valid_service_meta?).and_return(true)
          assert @service_order_detail.save
          @service_order_detail.reload.order.should == @merge_to_order
          assert @service_order_detail.save
          @service_order_detail.reload.order.should == @merge_to_order
        end

        it 'should update order_id but not destroy merge order if there is a complete active survey and other detail' do
          OrderDetail.any_instance.stub(:valid_service_meta?).and_return(true)
          @order.reload.order_details.size.should == 2
          assert @service_order_detail.save
          @service_order_detail.reload.order.should == @merge_to_order
          @order.reload.order_details.size.should == 1
        end

        it 'should update order_id and destroy merge order if there is a complete active survey and no other details' do
          OrderDetail.any_instance.stub(:valid_service_meta?).and_return(true)
          @order_detail.destroy
          assert @service_order_detail.save
          @service_order_detail.reload.order.should == @merge_to_order
          assert_raise(ActiveRecord::RecordNotFound) { Order.find @order.id }
        end
      end

      context 'instrument' do
        before :each do
          @instrument = create(:instrument,
                                            facility: @facility,
                                            facility_account_id: @facility_account.id,
                                            min_reserve_mins: 60,
                                            max_reserve_mins: 60)
          @instrument_order_detail=@order.order_details.create(attributes_for(:order_detail, product_id: @instrument.id, account_id: @account.id))
        end

        it 'should not update order_id if there is an incomplete reservation' do
          assert @instrument_order_detail.save
          @instrument_order_detail.reload.order.should == @order
          @order.reload.should be_to_be_merged
        end

        it 'should not affect non merge orders' do
          OrderDetail.any_instance.stub(:valid_reservation?).and_return(true)
          assert @instrument_order_detail.save
          @instrument_order_detail.reload.order.should == @merge_to_order
          assert @instrument_order_detail.save
          @instrument_order_detail.reload.order.should == @merge_to_order
        end

        it 'should update order_id but not destroy merge order if there is a complete reservation and other detail' do
          OrderDetail.any_instance.stub(:valid_reservation?).and_return(true)
          @order.reload.order_details.size.should == 2
          assert @instrument_order_detail.save
          @instrument_order_detail.reload.order.should == @merge_to_order
          @order.reload.order_details.size.should == 1
        end

        it 'should update order_id and destroy merge order if there is a complete reservation and no other details' do
          OrderDetail.any_instance.stub(:valid_reservation?).and_return(true)
          @order_detail.destroy
          assert @instrument_order_detail.save
          @instrument_order_detail.reload.order.should == @merge_to_order
          assert_raise(ActiveRecord::RecordNotFound) { Order.find @order.id }
        end
      end
    end

    def setup_merge_order
      @merge_to_order=@order.dup
      assert @merge_to_order.save
      @order.update_attribute :merge_with_order_id, @merge_to_order.id
      @order_detail.reload
    end
  end

  def set_cancellation_cost_for_all_policies(cost)
    PricePolicy.all.each do |price_policy|
      price_policy.update_attribute :cancellation_cost, cost
    end
  end
end
