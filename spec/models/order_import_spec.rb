require 'spec_helper'

describe OrderImport do

  it { should belong_to :creator }
  it { should belong_to :upload_file }
  it { should belong_to :error_file }
  it { should validate_presence_of :upload_file_id }
  it { should validate_presence_of :created_by }

end
