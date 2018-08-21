# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifier do
  before :each do
    @user = FactoryBot.create(:user)
    @facility = FactoryBot.create(:facility)
    @order_detail = place_and_complete_item_order(@user, @facility)
  end

  context "order_detail_status_change" do
    context "all order status emails render" do
      # Find all the files that start with order_status_changed_to, find the statuses and
      # get the uniq ones.
      @files = Dir["app/views/notifier/order_status_changed_to_*"].map { |a| File.basename(a) }
      @files = @files.map { |f| f.match(/order_status_changed_to_(.*)\.(html|text)\.(haml|erb)$/)[1] }.uniq

      @files.each do |f|
        it "should render template order_status_changed_to_#{f} successfully" do
          expect do
            Notifier.order_detail_status_change(@order_detail, nil, OrderStatus.find_or_create_by(name: f.titleize), "to@example.org")
          end.not_to raise_error
        end
      end
    end
  end
end
