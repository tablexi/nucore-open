require 'spec_helper'; require 'controller_spec_helper'

describe FacilityOrderDetailsController do
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
    @price_group=Factory.create(:price_group, :facility => @authable)
    @price_policy=Factory.create(:item_price_policy, :item => @product, :price_group => @price_group)
    @order_detail=Factory.create(:order_detail, :order => @order, :product => @product, :price_policy => @price_policy)
    @params={ :facility_id => @authable.url_name, :order_id => @order.id, :id => @order_detail.id }
  end


  context 'edit' do

    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_operators_only

  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
    end

    it_should_allow_operators_only

  end


  context 'resolve_dispute' do

    before :each do
      @method=:post
      @action=:resolve_dispute
      @order_detail.dispute_at=Time.zone.now
      @order_detail.dispute_reason='got charged too much'
      assert @order_detail.save
      @params[:order_detail_id]=@params[:id]
      @params.delete(:id)
    end

    it_should_require_login

    it_should_allow :staff do
      # abuse of API since we're not expecting success
      should render_template('404.html.erb')
    end

    it_should_allow_all facility_managers do
      should respond_with :success
    end

  end


  context 'show' do

    before :each do
      @method=:get
      @action=:show
    end

    it_should_allow_operators_only

  end


  context 'new_price' do

    before :each do
      @method=:get
      @action=:new_price
      @params[:order_detail_id]=@params[:id]
      @params.delete(:id)
    end

    it_should_allow_operators_only

  end

end