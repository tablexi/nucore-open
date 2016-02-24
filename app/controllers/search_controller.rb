class SearchController < ApplicationController
  before_action :authenticate_user!
  before_action :check_acting_as

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

  # ApplicationController#current_ability depends on current_facility being set
  # correctly. Since ApplicationController#current_facility loads based on the
  # facility's url_name, we need to override to load it through its id instead.
  def current_facility
    @facility ||= load_facility
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
