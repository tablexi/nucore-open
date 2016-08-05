require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityOrdersController do
  let(:account) { @account }
  let(:facility) { @authable }
  let(:product) { @product }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryGirl.create(:facility)
    @facility_account = FactoryGirl.create(:facility_account, facility: @authable)
    @product = FactoryGirl.create(:item,
                                  facility_account: @facility_account,
                                  facility: @authable,
                                 )
    @account = create_nufs_account_with_owner :director
    @order_detail = place_product_order(@director, @authable, @product, @account)
    @order_detail.order.update_attributes!(state: "purchased")
    @params = { facility_id: @authable.url_name }
  end

  context '#assign_price_policies_to_problem_orders' do
    let(:order_details) do
      Array.new(3) do
        order_detail = place_and_complete_item_order(@director, facility)
        order_detail.update_attribute(:price_policy_id, nil)
        order_detail
      end
    end

    let(:order_detail_ids) { order_details.map(&:id) }

    before :each do
      @method = :post
      @action = :assign_price_policies_to_problem_orders
    end

    context "when compatible price policies exist" do
      let(:price_group) { create(:price_group, facility: facility) }

      before :each do
        create(:account_price_group_member, account: account, price_group: price_group)

        order_details.each do |order_detail|
          order_detail.update_attribute(:account_id, account.id)
          order_detail.product.item_price_policies.create(attributes_for(
                                                            :item_price_policy, price_group_id: price_group.id))
        end

        do_request
      end

      it_should_allow_operators_only :redirect do
        expect(OrderDetail.where(id: order_detail_ids, problem: false).count)
          .to eq order_details.count
      end
    end

    context "when no compatible price policies exist" do
      before :each do
        ItemPricePolicy.all.each(&:destroy)
        do_request
      end

      it_should_allow_operators_only :redirect do
        expect(OrderDetail.where(id: order_detail_ids, problem: true).count)
          .to eq order_details.count
      end
    end
  end

  context '#batch_update' do
    before :each do
      @method = :post
      @action = :batch_update
    end

    it_should_allow_operators_only :redirect
  end

  context '#disputed' do
    before :each do
      @method = :get
      @action = :disputed
    end

    it_should_allow_managers_only
  end

  context '#index' do
    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_operators_only {}

    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :director
      end
      %w(order_number date product assigned_to status).each do |sort|
        it "should not blow up for sort by #{sort}" do
          @params[:sort] = sort
          do_request
          expect(response).to be_success
          expect(assigns[:order_details]).not_to be_nil
          expect(assigns[:order_details].first).not_to be_nil
        end
      end

      it "should not return reservations" do
        # setup_reservation overwrites @order_detail
        @order_detail_item = @order_detail
        @order_detail_reservation = setup_reservation(@authable, @facility_account, @account, @director)
        @reservation = place_reservation(@authable, @order_detail_reservation, Time.zone.now + 1.hour)

        expect(@authable.reload.order_details).to contain_all [@order_detail_item, @order_detail_reservation]
        do_request
        expect(assigns[:order_details]).to eq([@order_detail_item])
      end
    end
  end

  describe '#show' do
    before do
      maybe_grant_always_sign_in :admin
      @method = :get
      @action = :show
      @params.merge!(id: @order_detail.order.id)
    end

    describe "with an order detail with no cost assigned" do
      it "renders" do
        expect(@order_detail.actual_cost).to be_nil
        expect(@order_detail.estimated_cost).to be_nil
        expect { do_request }.not_to raise_error
      end
    end
  end

  context '#show_problems' do
    before :each do
      @method = :get
      @action = :show_problems
    end

    it_should_allow_managers_only
  end

  context '#send_receipt' do
    before :each do
      @method = :post
      @action = :send_receipt
      @params[:id] = @order.id
      request.env["HTTP_REFERRER"] = facility_order_path @authable, @order
      ActionMailer::Base.deliveries.clear
    end

    it_should_allow_operators_only :redirect, "to send a receipt" do
      expect(flash[:notice]).to be_present
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to include("Order Receipt")
      expect(mail.from.first).to eq(Settings.email.from)
      assert_redirected_to facility_order_path(@authable, @order)
    end
  end

  context '#update' do
    before :each do
      @method = :put
      @action = :update
      @params.merge!(id: @order.id,
                     product_add: @product.id,
                     product_add_quantity: 0)
    end

    it_should_allow_operators_only :redirect, "to submit product quantity 0 and get failure notice" do
      expect(flash[:notice]).to be_present
      assert_redirected_to facility_order_path(@authable, @order)
    end

    context "with quantity" do
      before :each do
        @params[:product_add_quantity] = 1
        @order.order_details.each(&:destroy)
      end

      it_should_allow :director, "to add an item to existing order directly" do
        assert_no_merge_order @order, @product
      end

      context "with instrument" do
        before :each do
          @instrument = FactoryGirl.create(:instrument,
                                           facility: @authable,
                                           facility_account: @facility_account,
                                           min_reserve_mins: 60,
                                           max_reserve_mins: 60)
          @params[:product_add] = @instrument.id
        end

        it_should_allow :director, "to add an instrument to existing order via merge" do
          assert_merge_order @order, @instrument
        end
      end

      context "with service" do
        before :each do
          @service = @authable.services.create(FactoryGirl.attributes_for(:service, facility_account_id: @facility_account.id))
          @params[:product_add] = @service.id
        end

        context "with active survey" do
          before :each do
            allow_any_instance_of(Service).to receive(:active_survey?).and_return(true)
            allow_any_instance_of(Service).to receive(:active_template?).and_return(false)
            allow_any_instance_of(OrderDetail).to receive(:valid_service_meta?).and_return(false)
          end

          it_should_allow :director, "to add a service to existing order via merge" do
            assert_merge_order @order, @service
          end
        end

        context "with active template" do
          before :each do
            allow_any_instance_of(Service).to receive(:active_survey?).and_return(false)
            allow_any_instance_of(Service).to receive(:active_template?).and_return(true)
            allow_any_instance_of(OrderDetail).to receive(:valid_service_meta?).and_return(false)
          end

          it_should_allow :director, "to add an service to existing order via merge" do
            assert_merge_order @order, @service
          end
        end

        context "with nothing active" do
          before :each do
            allow_any_instance_of(Service).to receive(:active_survey?).and_return(false)
            allow_any_instance_of(Service).to receive(:active_template?).and_return(false)
          end

          it_should_allow :director, "to add an service to existing order directly" do
            assert_no_merge_order @order, @service
          end
        end
      end

      context "with bundle" do
        before :each do
          @bundle = @authable.bundles.create(FactoryGirl.attributes_for(:bundle, facility_account_id: @facility_account.id))
          @params[:product_add] = @bundle.id
          BundleProduct.create!(bundle: @bundle, product: @product, quantity: 1)
        end

        context "has items" do
          before :each do
            item = FactoryGirl.create(:item, facility_account: @facility_account, facility: @authable)
            BundleProduct.create!(bundle: @bundle, product: item, quantity: 1)
          end

          it_should_allow :director, "to add an item to existing order directly" do
            assert_no_merge_order @order, @bundle, 2
          end
        end

        context "has instrument" do
          before :each do
            @instrument = FactoryGirl.create(:instrument,
                                             facility: @authable,
                                             facility_account: @facility_account,
                                             min_reserve_mins: 60,
                                             max_reserve_mins: 60)
            BundleProduct.create!(bundle: @bundle, product: @instrument, quantity: 1)
          end

          it_should_allow :director, "to add an instrument to existing order via merge" do
            assert_merge_order @order, @bundle, 1, 1
          end
        end

        context "has service" do
          before :each do
            @service = @authable.services.create(FactoryGirl.attributes_for(:service, facility_account_id: @facility_account.id))
            BundleProduct.create!(bundle: @bundle, product: @service, quantity: 1)
          end

          context "with active survey" do
            before :each do
              allow_any_instance_of(Service).to receive(:active_survey?).and_return(true)
              allow_any_instance_of(Service).to receive(:active_template?).and_return(false)
              allow_any_instance_of(OrderDetail).to receive(:valid_service_meta?).and_return(false)
            end

            it_should_allow :director, "to add a bundle to existing order via merge" do
              assert_merge_order @order, @bundle, 1, 1
            end
          end

          context "with active template" do
            before :each do
              allow_any_instance_of(Service).to receive(:active_survey?).and_return(false)
              allow_any_instance_of(Service).to receive(:active_template?).and_return(true)
              allow_any_instance_of(OrderDetail).to receive(:valid_service_meta?).and_return(false)
            end

            it_should_allow :director, "to add a bundle to existing order via merge" do
              assert_merge_order @order, @bundle, 1, 1
            end
          end

          context "with nothing active" do
            before :each do
              allow_any_instance_of(Service).to receive(:active_survey?).and_return(false)
              allow_any_instance_of(Service).to receive(:active_template?).and_return(false)
            end

            it_should_allow :director, "to add a bundle to existing order directly" do
              assert_no_merge_order @order, @bundle, 2
            end
          end
        end
      end
    end

    def assert_update_success(order, product)
      if product.is_a? Bundle
        order.order_details.each do |od|
          expect(od.order_status).to eq(OrderStatus.default_order_status)
          expect(product.products).to be_include(od.product)
        end
      else
        order_detail = order.order_details[0]
        expect(order_detail.product).to eq(product)
        expect(order_detail.order_status).to eq(OrderStatus.default_order_status)
      end

      if order.to_be_merged?
        expect(flash[:error]).to be_present
      else
        expect(flash[:notice]).to be_present
      end

      assert_redirected_to facility_order_path(@authable, order.to_be_merged? ? order.merge_order : order)
    end

    def assert_no_merge_order(original_order, product, detail_count = 1)
      expect(original_order.reload.order_details.size).to eq(detail_count)
      assert_update_success original_order, product
    end

    def assert_merge_order(original_order, product, detail_count = 1, original_detail_count = 0)
      expect(original_order.reload.order_details.size).to eq(original_detail_count)
      merges = Order.where(merge_with_order_id: original_order.id)
      expect(merges.size).to eq(1)
      merge_order = merges.first
      expect(merge_order.merge_order).to eq(original_order)
      expect(merge_order.facility_id).to eq(original_order.facility_id)
      expect(merge_order.account_id).to eq(original_order.account_id)
      expect(merge_order.user_id).to eq(original_order.user_id)
      expect(merge_order.created_by).to eq(@director.id)
      expect(merge_order.ordered_at).to be_blank
      expect(merge_order.order_details.size).to eq(detail_count)
      expect(MergeNotification.count).to eq(detail_count)
      assert_update_success merge_order, product
    end
  end

  context '#tab_counts' do
    before :each do
      @method = :get
      @action = :tab_counts
      @order_detail2 = FactoryGirl.create(:order_detail, order: @order, product: @product)

      expect(@authable.order_details.non_reservations.new_or_inprocess.size).to eq(2)

      @problem_order_details = (1..3).map do |_i|
        order_detail = place_and_complete_item_order(@staff, @authable)
        order_detail.update_attributes(price_policy_id: nil)
        order_detail
      end

      @disputed_order_details = (1..4).map do |_i|
        order_detail = place_and_complete_item_order(@staff, @authable)
        order_detail.update_attributes(dispute_at: Time.zone.now,
                                       dispute_resolved_at: nil,
                                       dispute_reason: "because")
        order_detail
      end
      expect(@authable.order_details.in_dispute.size).to eq(4)

      @params.merge!(tabs: %w(new_or_in_process_orders disputed_orders problem_order_details))
    end

    it_should_allow_operators_only {}

    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :director
      end
      it "should get only new if thats all you ask for" do
        @authable.order_details.non_reservations.new_or_inprocess.to_sql
        @params[:tabs] = ["new_or_in_process_orders"]
        do_request
        expect(response).to be_success
        body = JSON.parse(response.body)
        expect(body.keys).to contain_all ["new_or_in_process_orders"]
        expect(body["new_or_in_process_orders"]).to eq(2)
      end

      it "should get everything if you ask for it" do
        do_request
        expect(response).to be_success
        body = JSON.parse(response.body)
        expect(body.keys).to contain_all %w(new_or_in_process_orders disputed_orders problem_order_details)
        expect(body["new_or_in_process_orders"]).to eq(2)
        expect(body["problem_order_details"]).to eq(3)
        expect(body["disputed_orders"]).to eq(4)
      end
    end
  end
end
