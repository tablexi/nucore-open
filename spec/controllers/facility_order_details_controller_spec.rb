# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityOrderDetailsController do
  render_views

  let(:order_detail) { @order_detail }

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:setup_facility)
    @product = FactoryBot.create(:item,
                                 facility: @authable,
                                )
    @account = create_nufs_account_with_owner :director
    @order = FactoryBot.create(:order,
                               facility: @authable,
                               user: @director,
                               created_by: @director.id,
                               account: @account,
                               ordered_at: Time.zone.now,
                               state: "purchased",
                              )
    @price_group = FactoryBot.create(:price_group, facility: @authable)
    @price_policy = FactoryBot.create(:item_price_policy, product: @product, price_group: @price_group)
    @order_detail = FactoryBot.create(:order_detail, order: @order, product: @product, price_policy: @price_policy)
    @order_detail.set_default_status!
    @params = { facility_id: @authable.url_name, order_id: @order.id, id: @order_detail.id }
  end

  context "destroy" do
    before :each do
      @method = :delete
      @action = :destroy
    end

    it_should_allow_operators_only :redirect do
      expect(flash[:notice]).to be_present
      expect(@order_detail.reload).not_to be_frozen
      assert_redirected_to facility_order_path(@authable, @order)
    end

    context "merge order" do
      before :each do
        @clone = @order.dup
        assert @clone.save
        @order.update_attribute :merge_with_order_id, @clone.id
      end

      it_should_allow :director, "to destroy a detail that is part of a merge order" do
        expect { OrderDetail.find(order_detail.id) }
          .to raise_error ActiveRecord::RecordNotFound
        expect(flash[:notice]).to be_present
        assert_redirected_to facility_order_path(@authable, @clone)
      end
    end
  end

  def prepare_reservation
    @order_detail.update_attributes(price_policy: nil)
    @instrument = FactoryBot.create(:instrument, facility: @authable)
    @instrument_price_policy = FactoryBot.create(:instrument_price_policy,
                                                 product: @instrument,
                                                 price_group: @price_group,
                                                 usage_rate: 10,
                                                 usage_subsidy: 0)
    expect(@instrument_price_policy).to be_persisted
    allow_any_instance_of(Instrument).to receive(:cheapest_price_policy).and_return(@instrument_price_policy)
    @reservation = place_reservation @authable, @order_detail, 1.day.ago
    @order_detail.backdate_to_complete! @reservation.reserve_end_at
  end
end
