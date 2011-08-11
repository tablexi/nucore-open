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


  context 'new' do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_admin_only
  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
    end

    it_should_allow_admin_only
  end


  context 'edit' do

    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_admin_only
  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
    end

    it_should_allow_admin_only
  end


  context 'destroy' do

    before :each do
      @method=:delete
      @action=:destroy
      @params={ :id => Affiliate.first.id }
    end

    it_should_allow_admin_only
  end

end
