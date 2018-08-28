# frozen_string_literal: true

require "rails_helper"
RSpec.describe OrderDetailObserver do
  module DummyHooks

    class DummyHook1

      attr_accessor :settings
      def on_status_change(order_detail, old_status, new_status)
      end

    end

    class DummyHook2

      def on_status_change(order_detail, old_status, new_status)
      end

    end
    class DummyHook3; end

  end

  context "status change hooks" do
    # This before and after all is some nastiness to use a specific file for these tests, but
    # keep the original Settings for all other tests.
    before :all do
      Settings.reload_from_files(Rails.root.join("spec", "support", "order_detail_status_change_notification_test.yaml"))
    end

    after :all do
      reset_settings
    end

    before :each do
      @hooks = OrderDetailObserver.send(:status_change_hooks)
    end

    it "should support a list" do
      expect(@hooks[:list_with_duplicates].size).to eq(2)
    end
    it "should support a list with duplicates" do
      expect(@hooks[:list_with_duplicates].map(&:class)).to eq([DummyHooks::DummyHook1, DummyHooks::DummyHook1])
    end
    it "should support settings" do
      expect(@hooks[:item_with_settings].size).to eq(1)
      expect(@hooks[:item_with_settings].first.settings[:setting_1]).to eq("test")
      expect(@hooks[:item_with_settings].first.settings[:setting_2]).to eq("test2")
    end
    it "should support a single class" do
      expect(@hooks[:single_class].size).to eq(1)
      expect(@hooks[:single_class].first).to be_kind_of DummyHooks::DummyHook3
    end
    it "should support simple array" do
      expect(@hooks[:simple_array].size).to eq(2)
      expect(@hooks[:simple_array].map(&:class)).to eq([DummyHooks::DummyHook1, DummyHooks::DummyHook2])
    end
  end

  context "order details changes statuses" do
    after :all do
      reset_settings
    end

    before :each do
      Settings.reload!
      Settings.order_details.status_change_hooks = nil
      @facility = FactoryBot.create(:facility)
      @facility_account = FactoryBot.create(:facility_account, facility: @facility)
      @item = FactoryBot.create(:item, facility: @facility, facility_account: @facility_account)
      expect(@item).to be_valid
      FactoryBot.create :item_price_policy, product: @item, price_group: PriceGroup.base
      @user = FactoryBot.create(:user)
      @account = add_account_for_user(:user, @item)
      @order = @user.orders.create(FactoryBot.attributes_for(:order, created_by: @user.id, account: @account, facility: @facility))
      @order_detail = @order.order_details.create(FactoryBot.attributes_for(:order_detail).update(product_id: @item.id, account_id: @account.id))
      expect(@order_detail.state).to eq("new")
      expect(@order_detail.versions.size).to eq(1)
      expect(@order_detail.order_status).to be_nil

      expect(@order.validate_order!).to be true
      expect(@order.purchase!).to be true

      expect(@order_detail.reload.order.state).to eq("purchased")

      Settings.order_details.status_change_hooks = { in_process: "DummyHooks::DummyHook1", new: "DummyHooks::DummyHook2" }
      expect(@order_detail.order_status).to eq(OrderStatus.new_status)
    end
    it "should trigger a notification on change to inprogress" do
      expect_any_instance_of(DummyHooks::DummyHook1).to receive(:on_status_change).once.with(@order_detail, OrderStatus.new_status, OrderStatus.in_process).once
      expect(@order_detail.change_status!(OrderStatus.in_process)).to be true
    end
    it "should trigger a notification on change from in_process to new" do
      expect_any_instance_of(DummyHooks::DummyHook1).to receive(:on_status_change).once.with(@order_detail, OrderStatus.new_status, OrderStatus.in_process)
      expect(@order_detail.change_status!(OrderStatus.in_process)).to be true
      expect_any_instance_of(DummyHooks::DummyHook2).to receive(:on_status_change).once.with(@order_detail, OrderStatus.in_process, OrderStatus.new_status)
      expect(@order_detail.change_status!(OrderStatus.new_status)).to be true
    end
    it "should not trigger going from new to new" do
      expect_any_instance_of(DummyHooks::DummyHook2).to receive(:on_status_change).never
      expect(@order_detail.change_status!(OrderStatus.new_status)).to be true
    end
  end
end
