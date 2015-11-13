class SearchController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_acting_as

  ## return users of portal 'nucore'
  def user_search_results
    raise NUCore::PermissionDenied if session_user.blank?
    @limit = 25
    load_facility
    @price_group = PriceGroup.find(params[:price_group_id]) if params[:price_group_id].present?
    @account = Account.find(params[:account_id]) if params[:account_id].present?
    @product = Product.find(params[:product_id]) if params[:product_id].present?
    @users, @count = UserFinder.search(params[:search_term], @limit)

    render layout: false
  end

  private

  def load_facility
    @facility =
      if params[:facility_id].present?
        Facility.find(params[:facility_id])
      else
        Facility.cross_facility
      end
  end
end
