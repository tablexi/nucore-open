require 'spec_helper'
require 'controller_spec_helper'


describe OrderImportsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @params={ :facility_id => @authable.url_name }
  end


  context 'starting an import' do

    before :each do
      @action=:new
      @method=:get
    end

    it_should_allow_operators_only

  end


  context 'doing an import' do

    before :each do
      @action=:create
      @method=:post
    end

    it_should_allow_operators_only

  end

end
