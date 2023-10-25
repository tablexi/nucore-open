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

    previous_duration_rates = @product.duration_rates.reject { |dr| dr.id.blank? }

    @product.transaction do
      @product.duration_rates.destroy_all
      @product.update(instrument_duration_rate_params)
    end

    if @product.errors.blank?
      flash[:notice] = text("controllers.instrument_duration_rates.success")
      log_changes(previous_duration_rates)
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
    previous_duration_rates.sort_by! { |dr| dr.min_duration || 1_000 }
    new_duration_rates = @product.duration_rates.sort_by { |dr| dr.min_duration || 1_000 }

    if previous_duration_rates.length != new_duration_rates.length
      LogEvent.log(@product, :duration_rates_change, current_user, metadata: { before: build_log_metadata(previous_duration_rates), after: build_log_metadata(new_duration_rates) })
      return
    end

    changes = previous_duration_rates.zip(new_duration_rates).map do |previous_duration_rate, new_duration_rate|
     previous_duration_rate.min_duration != new_duration_rate.min_duration || previous_duration_rate.rate != new_duration_rate.rate
    end

    LogEvent.log(@product, :duration_rates_change, current_user, metadata: { before: build_log_metadata(previous_duration_rates), after: build_log_metadata(new_duration_rates) }) if changes.any?
  end

  def build_log_metadata(duration_rates)
    duration_rates.map { |dr| "#{dr.min_duration} min: $#{dr.rate}/hr" }.join(", ")
  end
end
