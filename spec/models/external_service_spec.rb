require 'spec_helper'

describe ExternalService do
  it { should validate_presence_of :location }
  it { should have_db_column :type }
end