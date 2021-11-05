# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe InstrumentRelaysController do
  render_views


  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:instrument) { FactoryBot.create(:instrument, facility: facility) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility
    @params = { id: instrument.relay, instrument_id: instrument.url_name, facility_id: facility.url_name }
  end

  context "new" do
    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_operators_only do
      is_expected.to render_template "new"
    end
  end

  context "edit" do
    before :each do
      @method = :get
      @action = :edit
    end

    it_should_allow_operators_only do
      is_expected.to render_template "edit"
    end
  end
end
