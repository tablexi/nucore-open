# frozen_string_literal: true

class RelaysActivationsController < ApplicationController

  before_action :authenticate_user!
  before_action :init_current_facility
  authorize_resource :facility

  def create
    current_facility.instruments.includes(:relay).select(&:has_real_relay?).each do |instrument|
      instrument.relay.activate
      instrument.instrument_statuses.create(is_on: true)
    end

    redirect_to facility_instruments_path(current_facility), flash: { notice: text("turned_on") }
  end

  def destroy
    current_facility.instruments.includes(:relay).select(&:has_real_relay?).each do |instrument|
      instrument.relay.deactivate
      instrument.instrument_statuses.create(is_on: false)
    end

    redirect_to facility_instruments_path(current_facility), flash: { notice: text("turned_off") }
  end

end
