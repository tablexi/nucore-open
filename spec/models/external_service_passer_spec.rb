require 'spec_helper'

describe ExternalServicePasser do
  it { should have_db_column :passer_type }
  it { should validate_presence_of :passer_id }
  it { should validate_presence_of :external_service_id }
end