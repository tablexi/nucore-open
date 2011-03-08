require 'spec_helper'; require 'controller_spec_helper'

describe FacilityJournalsController do
  integrate_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @journal=Factory.create(:journal, :facility => @authable, :created_by => @admin.id)
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
    end

    it_should_allow_managers_only

  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
      @params={ :facility_id => @authable.url_name, :id => @journal.id }
    end

    it_should_allow_managers_only

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params={ :facility_id => @authable.url_name }
    end

    it_should_allow_managers_only

  end


  context 'show' do

    before :each do
      @method=:get
      @action=:show
      @params={ :facility_id => @authable.url_name, :id => @journal.id }
    end

    it_should_allow_managers_only

  end

end