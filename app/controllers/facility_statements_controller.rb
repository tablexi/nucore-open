class FacilityStatementsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter { @facility = current_facility }

  load_and_authorize_resource :class => Statement

  include TransactionSearch

  layout 'two_column'

  def initialize
    @active_tab = 'admin_billing'
    super
  end

  # GET /facilities/:facility_id/statements
  def index
    @statements = current_facility.statements.find(:all, :order => 'statements.created_at DESC').paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/statements/new
  def new_with_search
    @order_details = @order_details.need_statement(@facility)
    @order_detail_action = :send_statements
    @layout = 'two_column_head'
  end

  # POST /facilities/:facility_id/statements/send_statements
  def send_statements

    if params[:order_detail_ids].nil? or params[:order_detail_ids].empty?
      flash[:error] = I18n.t 'controllers.facility_statements.send_statements.no_selection'
      redirect_to :action => :new
      return
    end
    @errors = []
    to_statement = {}
    OrderDetail.transaction do
      params[:order_detail_ids].each do |order_detail_id|
        od = nil
        begin
          od = OrderDetail.need_statement(current_facility).find(order_detail_id, :readonly => false)
          to_statement[od.account] ||= []
          to_statement[od.account] << od
        rescue => e
          @errors << I18n.t('controllers.facility_statements.send_statements.order_error', :order_detail_id => order_detail_id)
        end
      end

      @account_statements = {}
      to_statement.each do |account, order_details|
        statement = Statement.create!({:facility => current_facility, :account_id => account.id, :created_by => session_user.id})
        order_details.each do |od|
          StatementRow.create!({ :statement_id => statement.id, :amount => od.total, :order_detail_id => od.id })
          od.statement_id = statement.id
          @errors << "#{od} #{od.errors}" unless od.save
        end
        @account_statements[account] = statement
      end

      if @errors.any?
        flash[:error] = I18n.t('controllers.facility_statements.errors_html', :errors => @errors.join('<br/>')).html_safe
        raise ActiveRecord::Rollback
      else
        @account_statements.each do |account, statement|
          account.notify_users.each {|u| Notifier.statement(:user => u, :facility => current_facility, :account => account, :statement => statement).deliver }
        end
        account_list = @account_statements.map {|a,s| a.account_list_item }
        flash[:notice] = I18n.t('controllers.facility_statements.send_statements.success_html', :accounts => account_list.join('<br/>')).html_safe
      end
    end
    redirect_to :action => "new"
  end

  # GET /facilities/:facility_id/statements/:id
  def show
    @statement = Statement.find(params[:id])
  end
end
