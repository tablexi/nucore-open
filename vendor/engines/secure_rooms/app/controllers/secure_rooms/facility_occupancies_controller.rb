module SecureRooms

  class FacilityOccupanciesController < ApplicationController

    include NewInprocessController
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
    # Provided by NewInprocessController
    # def index
    # end

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
        .merge(SecureRooms::Occupancy.order(entry_at: :desc))
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
