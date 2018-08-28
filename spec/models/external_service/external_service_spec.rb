# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExternalService do
  it { is_expected.to validate_presence_of :location }
  it { is_expected.to have_db_column :type }
end
