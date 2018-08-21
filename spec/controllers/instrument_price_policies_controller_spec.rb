# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "price_policies_controller_shared_examples"

RSpec.describe InstrumentPricePoliciesController do
  render_views

  before(:all) { create_users }

  params_modifier = Class.new do
    def before_create(params)
      params.merge! charge_for: InstrumentPricePolicy::CHARGE_FOR[:reservation]
    end

    alias_method :before_update, :before_create
  end

  it_should_behave_like PricePoliciesController, :instrument, params_modifier.new
end
