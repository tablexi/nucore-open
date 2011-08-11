require 'spec_helper'
require 'controller_spec_helper'

describe AffiliatesController do
  render_views

  before(:all) { create_users }

  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_admin_only
  end

end
