class ProductAccessGroupsController < ApplicationController

  include BelongsToProductController
  admin_tab :all

  load_and_authorize_resource :product_access_group, through: :product

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  def index
  end

  def edit
  end

  def new
  end

  def update
    if @product_access_group.update_attributes(params[:product_access_group])
      flash[:notice] = "#{ProductAccessGroup.model_name.human} was successfully updated"
      redirect_to [current_facility, @product, ProductAccessGroup]
    else
      render action: :edit
    end
  end

  def create
    @product_access_group = @product.product_access_groups.new(params[:product_access_group])
    if @product_access_group.save
      flash[:notice] = "#{ProductAccessGroup.model_name.human} was successfully created"
      redirect_to [current_facility, @product, ProductAccessGroup]
    else
      render action: :new
    end
  end

  def destroy
    if @product_access_group.destroy
      flash[:notice] = "#{ProductAccessGroup.model_name.human} was deleted"
      redirect_to [current_facility, @product, ProductAccessGroup]
    else
      flash[:error] = "There was an error deleting the #{ProductAccessGroup.model_name.human}"
      redirect_to [:edit, current_facility, @product, ProductAccessGroup]
    end
  end

end
