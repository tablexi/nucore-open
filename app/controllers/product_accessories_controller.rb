class ProductAccessoriesController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_product
  load_and_authorize_resource :through => :product

  layout 'two_column'

  def initialize 
    @active_tab = 'admin_products'
    super
  end

  def index
    @product_accessory = @product.product_accessories.new
  end

  def create
    @product.accessory_ids += [params[:product_accessory][:accessory_id]]
    redirect_to :action => :index
  end

  def destroy
    @product_accessory.destroy
    redirect_to :action => :index
  end

  private
  def init_product
    @product = current_facility.products.find_by_url_name!(params[:product_id])
  end
end
