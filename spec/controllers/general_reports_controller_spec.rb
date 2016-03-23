require "rails_helper"
require "controller_spec_helper"
require "report_spec_helper"

RSpec.describe GeneralReportsController do
  include ReportSpecHelper

  run_report_tests([
                     { action: :product, index: 0, report_on_label: "Name", report_on: proc { |od| od.product.name } },
                     { action: :account, index: 1, report_on_label: "Description", report_on: proc { |od| od.account } },
                     { action: :account_owner, index: 2, report_on_label: "Name", report_on: proc { |od| owner = od.account.owner.user; "#{owner.last_name}, #{owner.first_name} (#{owner.username})" } },
                     { action: :purchaser, index: 3, report_on_label: "Name", report_on: proc { |od| usr = od.order.user; "#{usr.last_name}, #{usr.first_name} (#{usr.username})" } },
                     { action: :price_group, index: 4, report_on_label: "Name", report_on: proc { |od| od.price_policy ? od.price_policy.price_group.name : "Unassigned" } },
                   ])

  describe "time parameters", :timecop_freeze do
    let(:now) { Time.zone.parse("2014-03-06 12:00") }

    before do
      allow(controller).to receive(:authenticate_user!).and_return true
      allow(controller).to receive(:current_user).and_return build_stubbed(:user) # TODO: including this doesn't matter
      allow(controller).to receive(:current_facility).and_return build_stubbed(:facility)
    end

    context "defaults" do
      before { get :product }

      it "assigns the proper start date" do
        expect(assigns(:date_start)).to eq(Time.zone.local(2014, 2, 1))
      end

      it "assigns the proper end date" do
        expect(assigns(:date_end).to_i).to eq(Time.zone.local(2014, 2, 28, 23, 59, 59).to_i)
      end
    end

    context "with date parameters" do
      before { get :product, date_start: "01/01/2014", date_end: "01/31/2014" }

      it "assigns the start date to the beginning of the day" do
        expect(assigns(:date_start)).to eq(Time.zone.local(2014, 1, 1))
      end

      it "assigns the end date to the end of the day" do
        expect(assigns(:date_end).to_i).to eq(Time.zone.local(2014, 1, 31, 23, 59, 59).to_i)
      end
    end
  end

  context "report searching" do
    before :each do
      @complete_status = OrderStatus.complete.first

      @user = FactoryGirl.create(:user)
      @authable = FactoryGirl.create(:facility)
      @facility_account = @authable.facility_accounts.create!(FactoryGirl.attributes_for(:facility_account))
      @item = @authable.items.create!(FactoryGirl.attributes_for(:item, facility_account: @facility_account))

      @account = create_nufs_account_with_owner :user
      define_open_account @item.account, @account.account_number

      @order_detail_ordered_today_unfulfilled = place_product_order(@user, @authable, @item)

      @order_detail_ordered_yesterday_unfulfilled = place_product_order(@user, @authable, @item)
      @order_detail_ordered_yesterday_unfulfilled.order.update_attributes(ordered_at: 1.day.ago)

      @order_detail_ordered_yesterday_fulfilled_today_unreconciled = place_and_complete_item_order(@user, @authable, @account)
      @order_detail_ordered_yesterday_fulfilled_today_unreconciled.order.update_attributes(ordered_at: 1.day.ago)

      @order_detail_ordered_today_fulfilled_today_unreconciled = place_and_complete_item_order(@user, @authable, @account)

      @order_detail_ordered_today_fulfilled_next_month_unreconciled = place_and_complete_item_order(@user, @authable, @account)
      @order_detail_ordered_today_fulfilled_next_month_unreconciled.update_attributes(fulfilled_at: 1.month.from_now)

      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today = place_and_complete_item_order(@user, @authable, @account)
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today.order.update_attributes(ordered_at: 1.day.ago)
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today.update_attributes(fulfilled_at: 1.day.ago)
      @journal_today = FactoryGirl.create(:journal, facility: @authable, created_by: @admin.id, journal_date: Time.zone.now)
      @journal_today.create_journal_rows!([@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today])
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today.change_status!(OrderStatus.reconciled.first)

      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday = place_and_complete_item_order(@user, @authable, @account)
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday.order.update_attributes(ordered_at: 1.day.ago)
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday.update_attributes(fulfilled_at: 1.day.ago)
      @journal_yesterday = FactoryGirl.create(:journal, facility: @authable, created_by: @admin.id, journal_date: 1.day.ago)
      @journal_yesterday.create_journal_rows!([@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday])
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday.change_status!(OrderStatus.reconciled.first)

      @method = :xhr
      @action = :product
      @params = {
        facility_id: @authable.url_name,
        date_start: Time.zone.now.strftime("%m/%d/%Y"),
        date_end: 1.day.from_now.strftime("%m/%d/%Y"),
      }

      sign_in @admin
    end

    context "ordered_at search" do
      before :each do
        @params.merge!(date_range_field: :ordered_at)
      end

      it "should search" do
        do_request
        expect(response).to be_success
      end

      it "should search search unfulfilled" do
        @params[:status_filter] = [OrderStatus.new_os.first.id]
        do_request
        expect(assigns[:report_data]).to contain_all [@order_detail_ordered_today_unfulfilled]
      end

      it "should search fulfilled" do
        @params[:status_filter] = [@complete_status.id]
        do_request
        expect(assigns[:report_data]).to contain_all [@order_detail_ordered_today_fulfilled_today_unreconciled, @order_detail_ordered_today_fulfilled_next_month_unreconciled]
      end

      it "should search reconciled" do
        @params[:status_filter] = [OrderStatus.reconciled.first.id]
        do_request
        expect(assigns[:report_data]).to be_empty
      end

      it "should find reconciled that started yesterday" do
        @params[:status_filter] = [OrderStatus.reconciled.first.id]
        @params[:date_start] = 1.day.ago.strftime("%m/%d/%Y")
        do_request
        expect(assigns[:report_data]).to contain_all [@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday, @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today]
      end
    end

    context "fulfilled_at search" do
      before :each do
        @params.merge!(date_range_field: :fulfilled_at)
      end

      it "should have a problem if it searches unfulfilled" do
        @params[:status_filter] = [OrderStatus.new_os.first.id]
        do_request
        expect(assigns[:report_data]).to be_empty
      end

      it "should search fulfilled" do
        @params[:status_filter] = [@complete_status.id]
        do_request
        expect(assigns[:report_data]).to contain_all [@order_detail_ordered_yesterday_fulfilled_today_unreconciled, @order_detail_ordered_today_fulfilled_today_unreconciled]
      end

      it "should search reconciled" do
        @params[:status_filter] = [OrderStatus.reconciled.first.id]
        do_request
        expect(assigns[:report_data]).to be_empty
      end

      it "should find reconciled that started yesterday" do
        @params[:status_filter] = [OrderStatus.reconciled.first.id]
        @params[:date_start] = 1.day.ago.strftime("%m/%d/%Y")
        do_request
        expect(assigns[:report_data]).to contain_all [@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday, @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today]
      end
    end

    context "journaled_at search" do
      before :each do
        # change start date so we get an order detail
        @params.merge!(date_range_field: :journal_date)
      end

      it "should have a problem if it searches unfulfilled" do
        @params[:status_filter] = [OrderStatus.new_os.first.id]
        do_request
        expect(assigns[:report_data]).to be_empty
      end

      it "should have a problem if it searches unjournaled" do
        @params[:status_filter] = [@complete_status.id]
        do_request
        expect(assigns[:report_data]).to be_empty
      end

      it "should search reconciled" do
        @params[:status_filter] = [OrderStatus.reconciled.first.id]
        do_request
        expect(assigns[:report_data]).to eq([@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today])
      end

      it "should find reconciled that started yesterday" do
        @params[:status_filter] = [OrderStatus.reconciled.first.id]
        @params[:date_start] = 1.day.ago.strftime("%m/%d/%Y")
        do_request
        expect(assigns[:report_data]).to contain_all [@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today, @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday]
      end
    end
  end

  private

  def setup_extra_params(params)
    params.merge!(status_filter: [OrderStatus.complete.first.id], date_range_field: "fulfilled_at")
  end

  def report_headers(label)
    [label, "Quantity", "Total Cost", "Percent of Cost"]
  end

  def assert_report_params_init
    super
    expect(assigns(:status_ids)).to be_instance_of Array

    stati = if @params[:date_start].blank? && @params[:date_end].blank?
              [OrderStatus.complete.first, OrderStatus.reconciled.first]
            elsif @params[:status_filter].blank?
              []
            else
              @params[:status_filter].collect { |si| OrderStatus.find(si.to_i) }
            end

    status_ids = []

    stati.each do |stat|
      status_ids << stat.id
      status_ids += stat.children.collect(&:id) if stat.root?
    end

    expect(assigns(:status_ids)).to eq(status_ids)
  end

  def assert_report_init(_label)
    expect(response).to be_success
    expect(assigns(:total_quantity)).to be_instance_of Fixnum

    rows = assigns(:rows)
    ods = OrderDetail.all
    expect(rows.size).to eq(ods.size)

    rows.each do |row|
      expect(row).to be_instance_of Array
      expect(row.size).to eq(4)
    end

    ods.sort! { |a, b| yield(a) <=> yield(b) }

    ods.each_with_index do |od, i|
      expect(rows[i][0]).to eq(yield(od))
      expect(rows[i][1]).to eq(od.quantity)
      expect(rows[i][2]).to eq(od.total.to_i)
      expect(rows[i][3]).to eq(to_percent(od.total / assigns(:total_cost)))
    end
  end

  def assert_report_rendered_csv(label, &report_on)
    export_type = @params[:export_id]

    case export_type
    when "report"
      assert_report_init label, &report_on
      assert_report_download_rendered "#{@action}_report"
    when "report_data"
      assert_report_data_init label
    end
  end

  def assert_report_data_init(_label)
    expect(assigns :report_on).to be_a Proc
  end

end
