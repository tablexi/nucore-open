module SecureRooms

  class FacilityOccupanciesController < ApplicationController

    include ProblemOrderDetailsController
    include TabCountHelper

    admin_tab     :all
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility
    before_action :sanitize_sort_params, only: :index

    load_and_authorize_resource class: Occupancy

    SORTING_CLAUSES = {
      "entry_at" => "secure_rooms_occupancies.entry_at",
      "user_name" => ["users.last_name", "users.first_name"],
      "product_name" => "products.name",
      "payment_source" => "accounts.description",
    }.freeze

    def initialize
      super
      @active_tab = "admin_occupancies"
    end

    def index
      @order_details = new_or_in_process_orders.order(@order_by_clause).paginate(page: params[:page])
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
        .includes(
          { order: :user },
          :order_status,
          :product,
          :account,
          :occupancy,
        )
    end

    def problem_order_details
      current_facility
        .complete_problem_order_details
        .joins(:occupancy)
        .merge(SecureRooms::Occupancy.order(entry_at: :desc))
    end

    def sanitize_sort_params
      sort_clauses = Array(SORTING_CLAUSES[sort_column])
      @order_by_clause = sort_clauses.map do |clause|
        [clause, sort_direction].join(" ")
      end.join(", ")
    end

    def sort_column
      params[:sort] || "entry_at"
    end

    def sort_direction
      String(params[:dir]) =~ /asc/i ? "asc" : "desc"
    end

  end

end
