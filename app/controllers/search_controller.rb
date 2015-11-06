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
    load_users if params[:search_term].present?

    render layout: false
  end

  private

  def condition_sql
    <<-SQL
      (
          LOWER(first_name) LIKE ?
        OR
          LOWER(last_name) LIKE ?
        OR
          LOWER(username) LIKE ?
        OR
          LOWER(CONCAT(first_name, last_name)) LIKE ?
      )
    SQL
  end

  def load_facility
    @facility =
      if params[:facility_id].present?
        Facility.find(params[:facility_id])
      else
        all_facility
      end
  end

  def query_conditions
    @query_conditions ||=
      [condition_sql, search_term, search_term, search_term, search_term]
  end

  def search_term
    @search_term ||= generate_multipart_like_search_term(params[:search_term])
  end

  def load_users
    user_relation = User.where(query_conditions)
    @users = user_relation.order(:last_name, :first_name).limit(@limit)
    @count = user_relation.count
  end
end
