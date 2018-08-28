# frozen_string_literal: true

class ProductsController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as, except: [:index]
  before_action :init_current_facility

  load_and_authorize_resource

  layout "two_column"

  def initialize
    @active_tab = "admin_facility"
    super
  end

  # GET /products
  def index
    if current_facility.instruments.first
      redirect_to facility_instruments_path
    elsif current_facility.services.first
      redirect_to facility_services_path
    elsif current_facility.items.first
      redirect_to facility_items_path
    else
      redirect_to facility_instruments_path
    end
  end

end
