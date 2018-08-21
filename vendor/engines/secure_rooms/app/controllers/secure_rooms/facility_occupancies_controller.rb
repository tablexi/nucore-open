# frozen_string_literal: true

module SecureRooms

  class FacilityOccupanciesController < ApplicationController

    include OrderDetailsCsvExport
    include SortableColumnController
    include ProblemOrderDetailsController
    include TabCountHelper

    admin_tab     :all
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility

    load_and_authorize_resource class: Occupancy

    def initialize
      super
      @active_tab = "admin_occupancies"
    end

    # GET /facilities/:facility_id/occupancies
    def index
      order_details = new_or_in_process_orders.joins(:order)

      @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: { date_range_field: "ordered_at" })
      @search = TransactionSearch::Searcher.new(TransactionSearch::ProductSearcher).search(order_details, @search_form)
      @order_details = @search.order_details.includes(:order_status).joins_assigned_users.reorder(sort_clause)

      respond_to do |format|
        format.html { @order_details = @order_details.paginate(page: params[:page]) }
        format.csv { handle_csv_search }
      end
    end

    def dashboard
      @secure_rooms = current_facility.secure_rooms.active_plus_hidden.alphabetized
    end

    protected

    def show_problems_path
      show_problems_facility_occupancies_path(current_facility)
    end

    private

    def new_or_in_process_orders
      current_facility
        .order_details
        .new_or_inprocess
        .occupancies
        .includes(:occupancy, :account)
    end

    def problem_order_details
      current_facility
        .complete_problem_order_details
        .joins(:occupancy)
    end

    def sort_lookup_hash
      {
        "entry_at" => "secure_rooms_occupancies.entry_at",
        "user_name" => ["users.last_name", "users.first_name"],
        "product_name" => "products.name",
        "payment_source" => "accounts.description",
      }
    end

  end

end
