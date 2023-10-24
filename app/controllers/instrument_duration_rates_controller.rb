# frozen_string_literal: true

class InstrumentDurationRatesController < ApplicationController

  admin_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_instrument_duration_rates
  before_action :manage

  layout "two_column"

  MAX_DURATION_RATES = 4

  def edit
  end

  def update
    params[:duration_rates_attributes].reject! do |key, duration_rate|
      duration_rate["min_duration"].blank? && duration_rate["rate"].blank?
    end

    duration_rates = @product.duration_rates.reject { |dr| dr.id.blank? }

    @product.transaction do
      @product.duration_rates.destroy_all
      @product.update(instrument_duration_rate_params)
    end

    if @product.errors.blank?
      flash[:notice] = text("controllers.instrument_duration_rates.success")
      log_changes(duration_rates)
    end

    set_product_duration_rates
    render :edit
  end

  private

  def instrument_duration_rate_params
    params.permit(duration_rates_attributes: [:min_duration, :rate])
  end

  def manage
    authorize! :view_details, @product
    @active_tab = "admin_products"
  end

  def init_instrument_duration_rates
    @product = Product.find_by!(url_name: params[:id])

    return unless @product.is_a?(Instrument)

    set_product_duration_rates
  end

  def set_product_duration_rates
    @product_duration_rates = @product.duration_rates

    (MAX_DURATION_RATES - @product_duration_rates.length).times do
      @product_duration_rates.build
    end

    @product_duration_rates = @product_duration_rates.sort_by { |dr| dr.min_duration || 1_000 }
  end

  def log_changes(previous_duration_rates)
    log_created(previous_duration_rates)
    log_deleted(previous_duration_rates)
    log_updated(previous_duration_rates)
  end

  def log_created(previous_duration_rates)
    @product.duration_rates.each do |duration_rate|
      unless previous_duration_rates.find { |dr| dr.min_duration == duration_rate.min_duration }
        LogEvent.log(duration_rate, :create, current_user, metadata: { min_duration: duration_rate.min_duration, rate: duration_rate.rate })
      end
    end
  end

  def log_deleted(previous_duration_rates)
    previous_duration_rates.each do |duration_rate|
      unless @product.duration_rates.find { |dr| dr.min_duration == duration_rate.min_duration }
        LogEvent.log(duration_rate, :delete, current_user, metadata: { min_duration: duration_rate.min_duration, rate: duration_rate.rate })
      end
    end
  end

  def log_updated(previous_duration_rates)
    @product.duration_rates.each do |duration_rate|
      previous_duration_rate = previous_duration_rates.find { |dr| dr.min_duration == duration_rate.min_duration && dr.rate != duration_rate.rate }
      if previous_duration_rate
        LogEvent.log(duration_rate, :updated, current_user,  metadata: { min_duration: duration_rate.min_duration, previous_rate: previous_duration_rate.rate, new_rate: duration_rate.rate })
      end
    end
  end
end
