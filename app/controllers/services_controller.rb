class ServicesController < ProductsCommonController

  # GET /services
  def index
    @archived_product_count     = current_facility.services.archived.length
    @not_archived_product_count = current_facility.services.not_archived.length
    @product_name               = 'Services'
    if params[:archived].nil? || params[:archived] != 'true'
      @services = current_facility.services.not_archived
    else
      @services = current_facility.services.archived
    end

    @services.sort!
  end

end
