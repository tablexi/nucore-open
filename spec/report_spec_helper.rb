module ReportSpecHelper
  include DateHelper
  include ReportsHelper
  extend ActiveSupport::Concern


  included do |base|
    base.render_views

    base.before(:all) { create_users }

    base.before(:each) do
      @method=:get
      @authable=FactoryGirl.create(:facility)
      @params={
        :facility_id => @authable.url_name,
        :date_start => Time.zone.now.strftime('%m/%d/%Y'),
        :date_end => (Time.zone.now+1.year).strftime('%m/%d/%Y')
      }

      setup_extra_params(@params)
    end
  end


  module ClassMethods
    def run_report_tests(tests)
      tests.each do |test|
        context test[:action].to_s do
          before :each do
            @action=test[:action]
            [ :owner, :staff, :purchaser ].each do |user|
              acct=create_nufs_account_with_owner user
              place_and_complete_item_order(instance_variable_get("@#{user}"), @authable, acct)
              @order.ordered_at=parse_usa_date(@params[:date_start])+15.days
              assert @order.save
              setup_extra_test_data(user)
            end
          end


          it_should_allow_managers_and_senior_staff_only do
            assert_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
          end


          context 'ajax' do
            before :each do
              @method = :xhr
              # @params.merge!(:format => :js)
            end

            it_should_allow :director do
              assert_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
            end
          end


          context 'export' do
            before :each do
              @params.merge!(:format => :csv, :export_id => 'report')
            end

            it_should_allow :director do
              assert_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
            end

            context 'export data' do
              before :each do
                @params[:export_id]='report_data'
              end

              it_should_allow :director do
                assert_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
              end
            end
          end
        end
      end
    end
  end


  private

  def setup_extra_params(params)
  end


  def setup_extra_test_data(user)
  end


  def report_headers(label)
    raise 'Including class must implement!'
  end


  def assert_report_init(label, &report_on)
    raise 'Including class must implement!'
  end


  def assert_report_data_init(label)
    raise 'Including class must implement!'
  end


  def export_all_request?
    @params.has_key?(:export_id) && @params[:export_id] == 'report_data'
  end


  def assert_report_params_init
    now=Date.today
    date_start=Date.new(now.year, now.month, 1) - 1.month

    if @params[:date_start].blank?
      assigns(:date_start).should == date_start
    else
      assigns(:date_start).should == parse_usa_date(@params[:date_start]).beginning_of_day
    end

    if @params[:date_end].blank?
      date_end=date_start + 42.days
      assigns(:date_end).should == Date.new(date_end.year, date_end.month) - 1.day
    else
      assigns(:date_end).should == parse_usa_date(@params[:date_end]).end_of_day
    end
  end


  def assert_report_download_rendered(filename)
    @response.headers['Content-Type'].should == 'text/csv'
    filename += "_#{assigns(:date_start).strftime("%Y%m%d")}-#{assigns(:date_end).strftime("%Y%m%d")}.csv"
    @response.headers["Content-Disposition"].should == "attachment; filename=\"#{filename}\""
    should respond_with :success
  end


  def assert_report_rendered(tab_index, label, &report_on)
    assert_report_params_init
    assigns(:headers).should == report_headers(label)
    assigns(:selected_index).should == tab_index

    format=@params[:format]
    format=:html unless format

    if format == :html
      if @method == :xhr
        assert_report_init label, &report_on
        should render_template 'reports/report_table'
      else
        should render_template 'reports/report'
      end
    elsif format == :csv
      export_type=@params[:export_id]

      case export_type
        when 'report'
          assert_report_init label, &report_on
        when 'report_data'
          assert_report_data_init label
      end

      assert_report_download_rendered "#{@action}_#{export_type}"
    end
  end

end
