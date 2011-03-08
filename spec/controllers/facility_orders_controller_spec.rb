require 'spec_helper'; require 'controller_spec_helper'

describe FacilityOrdersController do
  integrate_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @product=Factory.create(:item,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @account=Factory.create(:nufs_account)
    @order=Factory.create(:order,
      :facility => @authable,
      :user => @director,
      :created_by => @director.id,
      :account => @account,
      :ordered_at => Time.zone.now
    )
    @order_detail=Factory.create(:order_detail, :order => @order, :product => @product)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_operators_only

  end


  context 'show' do

    before :each do
      @method=:get
      @action=:show
      @params.merge!(:id => @order.id)
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      assigns(:order).should == @order
      should render_template 'show.html.erb'
    end

  end


  context 'batch_update' do

    before :each do
      @method=:post
      @action=:batch_update
    end

    it_should_allow_operators_only :redirect

  end


  context 'review' do

    before :each do
      @method=:get
      @action=:review
    end

    it_should_allow_managers_only

  end


  context 'review_batch_update' do

    before :each do
      @method=:post
      @action=:review_batch_update
    end

    it_should_allow_managers_only :redirect

  end


  context 'disputed' do

    before :each do
      @method=:get
      @action=:disputed
    end

    it_should_allow_operators_only

  end

end
