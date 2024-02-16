# frozen_string_literal: true

class QuickActionsController < ApplicationController
  before_action :authenticate_user!
  load_resource :facility, find_by: :url_name
  load_resource :instrument, through: :facility, find_by: :url_name
  before_action :get_startable_reservation

  # - If the user has an upcoming reservation (within the move up window), ask if they would like to start it (or end it)
  # - If the user has no reservation, redirect them to the form to create one

  # GET /facilities/:facility_id/instruments/:instrument_id/quick_actions
  def index
  end

  def update
  end

  private

  def get_startable_reservation
    @reservations = current_user.reservations.where(product_id: @instrument.id)
    @startable = @reservations.find(&:startable_now?)
    @ongoing = @reservations.ongoing.first
  end
end
