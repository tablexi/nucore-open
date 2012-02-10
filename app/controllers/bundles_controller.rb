class BundlesController < ProductsCommonController
    # GET /bundles
  def index
    @archived_product_count     = current_facility.bundles.archived.length
    @not_archived_product_count = current_facility.bundles.not_archived.length
    @product_name               = 'Bundles'
    if params[:archived].nil? || params[:archived] != 'true'
      @bundles = current_facility.bundles.find(:all, :conditions => {'is_archived' => false})
    else
      @bundles = current_facility.bundles.archived.all
    end
  end
  
end
