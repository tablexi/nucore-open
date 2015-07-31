require 'spec_helper'

describe ExternalService do
  it { is_expected.to validate_presence_of :location }
  it { is_expected.to have_db_column :type }
end