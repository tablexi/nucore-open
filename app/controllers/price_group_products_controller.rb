class PriceGroupProductsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_price_group_products

  load_and_authorize_resource

  layout 'two_column'


  def initialize
    @active_tab = 'admin_products'
    super
  end


  def edit
  end


  def update
    window_errors=[]

    @price_groups.each do |pg|
      pg_key="price_group_#{pg.id}".to_sym
      pgp=PriceGroupProduct.find_by_price_group_id_and_product_id(pg.id, @product.id)

      if params[pg_key][:purchase] =~ /no/i
        pgp.destroy if pgp
      else
        res_win=params[pg_key][:reservation_window]

        if @is_instrument and res_win.blank?
          window_errors << pg.name
        else
          pgp=PriceGroupProduct.create!(:price_group => pg, :product => @product) unless pgp
          pgp.reservation_window=res_win.to_i if @is_instrument
          pgp.save!
        end
      end
    end

    if window_errors.blank?
      flash[:notice]='Pricing restrictions successfully updated.'
    else
      flash[:error]="Please assign a reservation window for the #{window_errors.to_sentence}"
    end

    redirect_to edit_facility_price_group_product_path(current_facility, @product)
  end

  
  private
  
  def init_price_group_products
    @product=Product.find_by_url_name!(params[:id])
    @is_instrument=@product.is_a? Instrument
    @price_groups=PriceGroup.all
    @price_group_products=PriceGroupProduct.find_all_by_product_id(@product.id)
    @price_group_product=@price_group_products.first # for CanCan authorization
  end

end