class ProductDisplayGroupsController < ApplicationController
  layout "two_column"

  def index
    @product_display_groups = current_facility.product_display_groups.sorted
    @ungrouped_products = current_facility.products.without_display_group
  end

  def create
    binding.pry
  end
end
