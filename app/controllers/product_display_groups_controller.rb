class ProductDisplayGroupsController < ApplicationController
  layout "two_column"

  admin_tab :all
  before_action :authenticate_user!
  before_action :init_current_facility
  load_and_authorize_resource through: :current_facility
  before_action :load_ungrouped_products

  def index
    @product_display_groups = @product_display_groups.sorted
  end

  def new
  end

  def create
    if @product_display_group.save
      redirect_to({ action: :index }, notice: text("create.success"))
    else
      render :new, alert: text("create.error")
    end
  end

  def edit
  end

  def update
    if @product_display_group.update(product_display_group_params)
      redirect_to({ action: :index }, notice: text("update.success"))
    else
      render :edit, alert: text("update.error")
    end
  end

  def destroy
    @product_display_group.destroy
    redirect_to({ action: :index }, notice: text("destroy.success"))
  end

  private

  def product_display_group_params
    params.require(:product_display_group).permit(:name, product_ids: [])
  end

  def load_ungrouped_products
    @ungrouped_products = current_facility.products.without_display_group.alphabetized
  end

end
