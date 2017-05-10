module SecureRooms

  class FacilityOccupanciesController < ApplicationController

    include ProblemOrderDetailsController
    include TabCountHelper

    admin_tab     :all
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility

    load_and_authorize_resource class: Occupancy

    ORDER_BY_CLAUSE_OVERRIDES_BY_SORTABLE_COLUMN = {
      "date" => "secure_rooms_occupancies.entry_at",
      "reserve_range" => "CONCAT(secure_rooms_occupancies.entry_at, secure_rooms_occupancies.exit_at)",
      "product_name"  => "products.name",
      "status"        => "order_statuses.name",
      "assigned_to"   => "CONCAT(assigned_users_order_details.last_name, assigned_users_order_details.first_name)",
      "reserved_by"   => "#{User.table_name}.first_name, #{User.table_name}.last_name",
    }.freeze

    helper_method :sort_column, :sort_direction

    def initialize
      super
      @active_tab = "admin_occupancies"
    end

    def index
      real_sort_clause = ORDER_BY_CLAUSE_OVERRIDES_BY_SORTABLE_COLUMN[sort_column] || sort_column
      order_by_clause = [real_sort_clause, sort_direction].join(" ")

      @order_details = new_or_in_process_orders(order_by_clause)
      @order_details = @order_details.paginate(page: params[:page])
    end

    protected

    def show_problems_path
      show_problems_facility_occupancies_path
    end

    private

    def new_or_in_process_orders(order_by_clause = "secure_rooms_occupancies.entry_at")
      current_facility.order_details.new_or_inprocess.occupancies
                      .includes(
                        { order: :user },
                        :order_status,
                        :occupancy,
                        :assigned_user,
                      )
                      .where("secure_rooms_occupancies.id IS NOT NULL")
                      .order(order_by_clause)
    end

    def problem_order_details
      current_facility
        .problem_occupancy_order_details
        .joins(:occupancy)
        .order("secure_rooms_occupancies.entry_at DESC")
    end

    def sort_column
      params[:sort] || "date"
    end

    def sort_direction
      (params[:dir] || "") =~ /asc/i ? "asc" : "desc"
    end

  end

end
