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
      "user_name" => "users.username",
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
      show_problems_facility_occupancies_path
    end

    private

    def new_or_in_process_orders
      current_facility
        .order_details
        .new_or_inprocess
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
      sort_clause = SORTING_CLAUSES[sort_column]
      @order_by_clause = [sort_clause, sort_direction].join(" ")
    end

    def sort_column
      params[:sort] || "entry_at"
    end

    def sort_direction
      (params[:dir] || "") =~ /asc/i ? "asc" : "desc"
    end

  end

end
