require "rails_helper"
require "controller_spec_helper"

RSpec.describe StatementsController do

  before(:all) do
    create_users
  end

  before(:each) do
    @authable = create_nufs_account_with_owner
  end

  # TODO: add specs for #show
end
