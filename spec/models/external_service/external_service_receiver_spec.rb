require 'spec_helper'

describe ExternalServiceReceiver do
  it { should have_db_column :receiver_type }
  it { should validate_presence_of :receiver_id }
  it { should validate_presence_of :external_service_id }
  it { should validate_presence_of :response_data }
end