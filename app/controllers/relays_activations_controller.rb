# frozen_string_literal: true

class RelaysActivationsController < ApplicationController

  before_action :authenticate_user!
  before_action :init_current_facility
  authorize_resource :facility

  def create
    relays.each(&:activate)
    redirect_to facility_instruments_path(current_facility), flash: { notice: text("turned_on") }
  rescue NetBooter::Error
    redirect_to facility_instruments_path(current_facility), flash: { alert: text("connection_error") }
  end

  def destroy
    relays.each(&:deactivate)
    redirect_to facility_instruments_path(current_facility), flash: { notice: text("turned_off") }
  rescue NetBooter::Error
    redirect_to facility_instruments_path(current_facility), flash: { alert: text("connection_error") }
  end

  private

  def relays
    current_facility.instruments.includes(:relay).select(&:has_real_relay?).map(&:relay)
  end

end
