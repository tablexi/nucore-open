class SearchController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_acting_as

  ## return users of portal 'nucore'
  def user_search_results
    raise NUCore::PermissionDenied unless session_user
    @limit       = 25
    @facility    = Facility.find(params[:facility_id]) if params[:facility_id]
    @price_group = PriceGroup.find(params[:price_group_id]) if params[:price_group_id]
    @account     = Account.find(params[:account_id]) if params[:account_id]
    @product     = Product.find(params[:product_id]) if params[:product_id]
    
    term = generate_multipart_like_search_term(params[:search_term])
    if params[:search_term].length > 0
      conditions = ["(LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(username) LIKE ? OR LOWER(CONCAT(first_name, last_name)) LIKE ?)", term, term, term, term]
      @users = User.find(:all, :conditions => conditions, :order => "last_name, first_name", :limit => @limit)
      @count = User.count(:all, :conditions => conditions)
    end
    render :layout => false
  end
end