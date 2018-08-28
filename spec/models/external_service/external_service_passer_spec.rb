# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExternalServicePasser do
  it { is_expected.to have_db_column :passer_type }
  it { is_expected.to validate_presence_of :passer_id }
  it { is_expected.to validate_presence_of :external_service_id }
end
