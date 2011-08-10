require 'spec_helper'
require 'controller_spec_helper'

describe GlobalSettingsController do
  render_views

  before(:all) { create_users }

  before(:each) { @authable=Factory.create(:facility) }


  context 'affiliates' do

    before :each do
      @method=:get
      @action=:affiliates
    end

    it_should_allow_admin_only

  end

end
