class ItemsController < ProductsCommonController
  
  # GET /items
  def index
    @archived_product_count     = current_facility.items.archived.length
    @not_archived_product_count = current_facility.items.not_archived.length
    @product_name               = 'Items'
    if params[:archived].nil? || params[:archived] != 'true'
      @items = current_facility.items.not_archived
    else
      @items = current_facility.items.archived
    end

    @items.sort!
  end

end
