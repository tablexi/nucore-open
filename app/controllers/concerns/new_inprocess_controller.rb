module NewInprocessController

  extend ActiveSupport::Concern

  included do
    helper_method :sort_column, :sort_direction
  end

  def index
    @order_details = new_or_in_process_orders
      .includes(
        { order: :user },
        :order_status,
        :assigned_user
      )
      .order(sort_lookup_hash[sort_column])
      .paginate(page: params[:page])
  end

  private

  def new_or_in_process_orders
    raise NotImplementedError
  end

  def sort_lookup_hash
    raise NotImplementedError
  end

  def sort_direction
    (params[:dir] || "") == "desc" ? "desc" : "asc"
  end

  def sort_column
    sort_lookup_hash.key?(params[:sort]) ? params[:sort] : sort_lookup_hash.keys.first
  end

end
