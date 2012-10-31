require 'spec_helper'

describe OrderImport do

  it { should validate_presence_of :upload_file_id }
  it { should validate_presence_of :created_by }

end
