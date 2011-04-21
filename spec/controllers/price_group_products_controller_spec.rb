require 'spec_helper'
require 'controller_spec_helper'

describe PriceGroupProductsController do
  integrate_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=@authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument=@authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @price_group_products=[]

    PriceGroup.all.each do |pg|
      price_group_product=PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pg.id, @instrument.id)
      price_group_product.reservation_window=14
      assert price_group_product.save
      @price_group_products << price_group_product
    end

    @params={ :facility_id => @authable.url_name, :id => @instrument.url_name }
  end


  context 'edit' do

    before :each do
      @method=:get
      @action=:edit
    end

    it_should_allow_managers_only do
      assert_init_price_group_products
      should render_template 'edit'
    end

  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update

      PriceGroup.all.each do |pg|
        @params.merge!({
          pg_key(pg) => { :reservation_window => 5, :purchase => 'Yes' }
        })
      end
    end


    it_should_allow_managers_only :redirect, 'to update existing PriceGroupProducts' do
      assert_init_price_group_products
      PriceGroupProduct.count.should == PriceGroup.count
      @price_group_products.each {|pgp| pgp.reload.reservation_window.should == 5 }
      assert_successful_update
    end


    it 'should remove PriceGroupProduct when a PriceGroup cannot purchase' do
      pg=PriceGroup.first
      @params[pg_key(pg)][:purchase]='no'
      PriceGroupProduct.count.should == PriceGroup.count
      maybe_grant_always_sign_in :director
      do_request
      PriceGroupProduct.count.should == PriceGroup.count-1
      assert_successful_update
    end


    it 'should create PriceGroupProducts when a PriceGroup can purchase' do
      pgp=@price_group_products.first
      pgp.destroy
      PriceGroupProduct.count.should == PriceGroup.count-1
      maybe_grant_always_sign_in :director
      do_request
      PriceGroupProduct.count.should == PriceGroup.count
      assert_successful_update
    end


    it 'should error if no reservation window given' do
      pg=PriceGroup.first
      @params[pg_key(pg)][:reservation_window]=''
      maybe_grant_always_sign_in :director
      do_request
      flash[:notice].should be_nil
      flash[:error].should_not be_nil
      assert_update_redirect
    end

  end


  private

  def pg_key(price_group)
    return "price_group_#{price_group.id}".to_sym
  end


  def assert_update_redirect
    assert_redirected_to edit_facility_price_group_product_path(@authable, @instrument)
  end


  def assert_successful_update
    flash[:notice].should_not be_nil
    flash[:error].should be_nil
    assert_update_redirect
  end


  def assert_init_price_group_products
    assigns[:product].should == @instrument
    PriceGroup.all.each {|pg| assigns[:price_groups].should be_include pg }
    @price_group_products.each {|pgp| assigns[:price_group_products].should be_include pgp }
    assigns[:price_group_products].should be_include assigns[:price_group_product]
  end

end